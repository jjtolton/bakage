:- use_module(bakage).
:- use_module(pkg(testpkg)).

main :-
    test_predicate(X),
    write('Test passed: '),
    write(X),
    nl.
