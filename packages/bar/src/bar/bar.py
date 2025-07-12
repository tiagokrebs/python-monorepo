"""Bar module that imports foo and adds 'bar'."""

from foo import get_foo


def run_bar() -> None:
    """Import foo and print its value plus 'bar'."""
    foo_value = get_foo()
    result = foo_value + "bar"
    print(result)
