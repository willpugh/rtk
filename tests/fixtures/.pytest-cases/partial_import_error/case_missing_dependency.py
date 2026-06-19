import rtk_missing_dependency_partial


def test_never_collected():
    assert rtk_missing_dependency_partial.available
