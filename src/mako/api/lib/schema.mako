<%!
    from util import (schema_markers, rust_doc_comment, mangle_ident, to_rust_type, put_and, 
                      IO_TYPES, activity_split, enclose_in, REQUEST_MARKER_TRAIT, mb_type, indent_all_but_first_by,
                      NESTED_TYPE_SUFFIX, RESPONSE_MARKER_TRAIT, split_camelcase_s, METHODS_RESOURCE, unique_type_name, 
                      PART_MARKER_TRAIT, canonical_type_name, TO_PARTS_MARKER, UNUSED_TYPE_MARKER, is_schema_with_optionals)
    from rust_struct import (RustStruct)
%>\
## Build a schema which must be an object
###################################################################################################################
###################################################################################################################
<%def name="_new_object(s, properties, c, allow_optionals)">\
<%
    rust_struct = RustStruct(s)
    struct_name = rust_struct.unique_type_name()
%>\
<% struct = 'pub struct ' + struct_name %>\
% if rust_struct.has_properties():
${struct} {
% for rust_property in rust_struct.properties():
    ${rust_property.description | rust_doc_comment, indent_all_but_first_by(1)}
    % if rust_property.name != rust_property.rust_safe_name():
    #[serde(rename="${rust_property.name}")]
    % endif
    pub ${rust_property.rust_safe_name()}: ${to_rust_type(schemas, rust_struct.id, rust_property.name, rust_property.raw_schema, allow_optionals=allow_optionals)},
% endfor
}
% elif rust_struct.has_additional_properties():
${struct}(${to_rust_type(schemas, rust_struct.id, NESTED_TYPE_SUFFIX, rust_struct.raw_schema, allow_optionals=allow_optionals)});
% else: ## it's an empty struct, i.e. struct Foo;
        ## However, to enable the empty JSON object to be parsed, we set one unused optional parameter.
${struct} { _never_set: Option<bool> }
% endif ## 'has_properties/has_additional_properties/empty' in s
</%def>

## Create new schema with everything.
## 's' contains the schema structure from json to build
###################################################################################################################
###################################################################################################################
<%def name="new(s, c)">\
<% 
    markers = schema_markers(s, c, transitive=True)
    # We always need Serialization support, as others might want to serialize the response, even though we will 
    # only deserialize it.
    # And since we don't know what others want to do, we implement Deserialize as well by default ... 
    traits = ['Clone', 'Debug', 'Serialize', 'Deserialize']
    
    nt_markers = schema_markers(s, c, transitive=False)
    allow_optionals = is_schema_with_optionals(nt_markers)
    
    # waiting for Default: https://github.com/rust-lang/rustc-serialize/issues/71
    if s.type == 'any':
        traits.remove('Default')

    s_type = unique_type_name(s.id)
%>\
<%block filter="rust_doc_comment">\
${doc(s, c)}\
</%block>
#[derive(${', '.join(traits)})]
% if s.type == 'object':
${_new_object(s, s.get('properties'), c, allow_optionals)}\
% elif s.type == 'array':
% if s.items.get('type') != 'object':
pub struct ${s_type}(${to_rust_type(schemas, s.id, NESTED_TYPE_SUFFIX, s, allow_optionals=allow_optionals)});
% else:
${_new_object(s, s.items.get('properties'), c, allow_optionals)}\
% endif ## array item != 'object'
% elif s.type == 'any':
## waiting for Default: https://github.com/rust-lang/rustc-serialize/issues/71
pub struct ${s_type}(json::Value);

impl Default for ${s_type} {
    fn default() -> ${s_type} {
        ${s_type}(json::Value::Null)
    }
}
% else:
<% assert False, "Object not handled: %s" % str(s) %>\
% endif ## type == ?

% for marker_trait in nt_markers:
% if marker_trait not in (TO_PARTS_MARKER, UNUSED_TYPE_MARKER):
impl ${marker_trait} for ${s_type} {}
% endif
% endfor

% if TO_PARTS_MARKER in nt_markers and allow_optionals:
impl ${TO_PARTS_MARKER} for ${s_type} {
    /// Return a comma separated list of members that are currently set, i.e. for which `self.member.is_some()`.
    /// The produced string is suitable for use as a parts list that indicates the parts you are sending, and/or
    /// the parts you want to see in the server response.
    fn to_parts(&self) -> String {
        let mut r = String::new();
        % for pn, p in s.properties.iteritems():
<%
            mn = 'self.' + mangle_ident(pn)
            rt = to_rust_type(schemas, s.id, pn, p, allow_optionals=allow_optionals)
            check = 'is_some()'
            if rt.startswith('Vec') or rt.startswith('HashMap'):
                check = 'len() > 0'
%>\
        if ${mn}.${check} { r = r + "${pn},"; }
        % endfor
        ## remove (possibly non-existing) trailing comma
        r.pop();
        r
    }
}
% endif
</%def>

#########################################################################################################
#########################################################################################################
<%def name="doc(s, c)">\
${s.get('description', 'There is no detailed description.')}
% if s.id in c.sta_map:

# Activities

This type is used in activities, which are methods you may call on this type or where this type is involved in. 
The list links the activity name, along with information about where it is used (one of ${put_and(enclose_in('*', IO_TYPES))}).

% for a, iot in c.sta_map[s.id].iteritems():
<%
    category, name, method = activity_split(a)
    name_suffix = ' ' + split_camelcase_s(name)
    if name == METHODS_RESOURCE:
        name_suffix = ''
    struct_url = 'struct.' + mb_type(name, method) + '.html'
    method_name = ' '.join(split_camelcase_s(method).split('.')) + name_suffix
    value_type = '|'.join(iot) or 'none'
%>\
* [${method_name}](${struct_url}) (${value_type})
% endfor
% else:

This type is not used in any activity, and only used as *part* of another schema.
% endif
% if s.type != 'object':

## for some reason, it's not shown in rustdoc ... 
The contained type is `${to_rust_type(schemas, s.id, s.id, s)}`.
%endif
</%def>
