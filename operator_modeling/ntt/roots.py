"""One fixed primitive root of unity per prime field, independent of earlier Sage calls."""


def fixedRoot(F, m: int):
    '''A primitive m-th root of unity of the prime field F, the same whatever was computed before: what
    `F.zeta(m)` returns in a fresh process (g^((q-1)/m) for a co-order up to 500000, g the field's
    multiplicative generator, else Sage's element of factored order, which is deterministic).'''
    from sage.all import Integer
    m = Integer(m)
    co = (F.order() - 1) // m
    if co * m != F.order() - 1:
        raise ValueError(f'no {m}th root of unity mod {F.order()}')
    if co <= 500000:
        return F.multiplicative_generator() ** co
    return F._element_of_factored_order(m.factor())
