#!/usr/bin/env python

import unittest

from rust_struct import RustStruct, RustStructProperty
from util_test import read_test_json_file


class RustStructTest(unittest.TestCase):
    def setUp(self):
        self.has_properties_schema = read_test_json_file('photoslibrary-api.json')['schemas']['BatchCreateMediaItemsRequest']
        self.has_additional_properties_schema = read_test_json_file('identitytoolkit-api.json')['schemas']['IdentitytoolkitRelyingpartyGetPublicKeysResponse']

    def test_description(self):
        struct_schema = self.has_properties_schema
        struct = RustStruct(struct_schema)
        self.assertEqual(struct.description, 'Request to create one or more media items in a user\'s Google Photos library.\nIf an `albumid` is specified, the media items are also added to that album.\n`albumPosition` is optional and can only be specified if an `albumId` is set.')

        del struct_schema['description']
        struct = RustStruct(struct_schema)
        self.assertEqual(struct.description, 'no description provided')


    def test_unique_type_name(self):
        struct_schema = self.has_properties_schema
        struct = RustStruct(struct_schema)
        self.assertEqual(struct.unique_type_name(), 'BatchCreateMediaItemsRequest')

        struct_schema['id'] = 'Result'
        struct = RustStruct(struct_schema)
        self.assertEqual(struct.unique_type_name(), 'ResultType')

    def test_id(self):
        struct_schema = self.has_properties_schema
        struct = RustStruct(struct_schema)
        self.assertEqual(struct.id, 'BatchCreateMediaItemsRequest')

    def test_has_properties(self):
        struct_schema = self.has_properties_schema
        struct = RustStruct(struct_schema)
        self.assertTrue(struct.has_properties())

        struct_schema = self.has_additional_properties_schema
        struct = RustStruct(struct_schema)
        self.assertFalse(struct.has_properties())

    def test_properties(self):
        struct_schema = self.has_properties_schema
        struct = RustStruct(struct_schema)
        properties = list(struct.properties())
        self.assertEqual(len(properties), 3)
        self.assertEqual(properties[0].name, 'albumId')

    def test_has_additional_properties(self):
        struct_schema = self.has_additional_properties_schema
        struct = RustStruct(struct_schema)
        self.assertTrue(struct.has_additional_properties())

        struct_schema = self.has_properties_schema
        struct = RustStruct(struct_schema)
        self.assertFalse(struct.has_additional_properties())


class RustStructPropertyTest(unittest.TestCase):
    def test_name(self):
        full_api_schema = read_test_json_file('photoslibrary-api.json')
        property_schema = full_api_schema['schemas']['BatchCreateMediaItemsRequest']['properties']['albumId']

        prop = RustStructProperty('albumId', property_schema)
        self.assertEqual(prop.name, 'albumId')

    def test_rust_safe_name(self):
        full_api_schema = read_test_json_file('photoslibrary-api.json')
        property_schema = full_api_schema['schemas']['BatchCreateMediaItemsRequest']['properties']['albumId']

        prop = RustStructProperty('albumId', property_schema)
        self.assertEqual(prop.rust_safe_name(), 'album_id')

    def test_description(self):
        full_api_schema = read_test_json_file('photoslibrary-api.json')
        property_schema = full_api_schema['schemas']['BatchCreateMediaItemsRequest']['properties']['albumId']

        prop = RustStructProperty('albumId', property_schema)
        self.assertEqual(prop.description, 'Identifier of the album where the media items are added. The media items\nare also added to the user\'s library. This is an optional field.')

        del property_schema['description']
        prop = RustStructProperty('albumId', property_schema)
        self.assertEqual(prop.description, 'no description provided')


def main():
    unittest.main()


if __name__ == '__main__':
    main()
