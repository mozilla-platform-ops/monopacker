import pytest

from monopacker.template_packer import handle_vars


def test_handle_vars():
    base = {"abc": 123, "foo": "bar", "blah": {"sub_foo": "sub_bar", "cow": "quack"}}
    override = {"abc": 456, "blah": {"cow": "moo"}}
    expected = {"abc": 456, "foo": "bar", "blah": {"sub_foo": "sub_bar", "cow": "moo"}}

    assert handle_vars(base, override) == expected
