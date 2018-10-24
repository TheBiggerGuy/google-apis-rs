#!/usr/bin/env python

import six

from util import unique_type_name, mangle_ident


class RustStructSchemaAssumtionFailure(AssertionError):
    pass


class RustStructProperty(object):
    def __init__(self, name, schema):
        self._name = name
        self._schema = schema

    @property
    def name(self):
        return self._name

    def rust_safe_name(self):
        return mangle_ident(self.name)

    @property
    def description(self):
        return self._schema.get('description', 'no description provided')

    @property
    def raw_schema(self):
        return self._schema


class RustStruct(object):
    def __init__(self, schema):
        self._schema = schema

        if sum((self.has_properties(), self.has_additional_properties())) != 1:
            raise RustStructSchemaAssumtionFailure('{}: Expecting one and only one: has_properties={}, has_additional_properties={} and is_empty={}'.format(self.id, self.has_properties(), self.has_additional_properties(), self.is_empty()))
        if 'variant' in self._schema:
            raise RustStructSchemaAssumtionFailure('{}: Variant in struct: Support was removed, see bb75c5b69871ec88c888618d0c3292741c9cffff'.format(self.id))

    @property
    def id(self):
        return self._schema['id']

    @property
    def description(self):
        return self._schema.get('description', 'no description provided')

    def unique_type_name(self):
        return unique_type_name(self.id)

    def has_properties(self):
        return 'properties' in self._schema

    def properties(self):
        for property_name, property_schema in six.iteritems(self._schema['properties']):
            yield RustStructProperty(property_name, property_schema)

    def has_additional_properties(self):
        return 'additionalProperties' in self._schema

    def is_empty(self):
        return not self.has_properties()

    @property
    def raw_schema(self):
        return self._schema


if __name__ == '__main__':
    raise AssertionError('For import only')
