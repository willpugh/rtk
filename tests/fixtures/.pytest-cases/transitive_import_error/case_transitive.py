from sample_package import VALUE


def test_never_collected():
    assert VALUE == 42
