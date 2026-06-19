import pytest


@pytest.fixture
def broken_setup():
    import rtk_missing_setup_dependency

    return rtk_missing_setup_dependency.VALUE
