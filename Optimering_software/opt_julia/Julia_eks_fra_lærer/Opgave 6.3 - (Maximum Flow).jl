using JuMP
using HiGHS

G = [
    0  8 11  2  0  0  0  0  0  0;  # København
    0  0  0  0  3  5  0  0  0  0;  # Rostock
    0  0  0  0 14 11  0  0  0  0;  # Putgarden
    0  0  0  0 10  0  0  0  0  0;  # Padborg
    0  0  0  0  0 12 12  0  0  0;  # Hamburg
    0  0  0  0  0  0  4 10 10  0;  # Berlin
    0  0  0  0  0  0  0  4 12 11;  # Strasbourg
    0  0  0  0  0  0  0  0 23 16;  # Bruxelles
    0  0  0  0  0  0  0  0  0 10;  # Liege
    0  0  0  0  0  0  0  0  0  0   # Paris
]

n = size(G, 1)

max_flow = Model(HiGHS.Optimizer)

@variable(max_flow, f[1:n, 1:n] >= 0)

@constraint(max_flow, [i = 1:n, j = 1:n], f[i, j] <= G[i, j])

@constraint(max_flow, [i = 2:n-1], sum(f[i, :]) == sum(f[:, i]))

@objective(max_flow, Max, sum(f[1, :]))

optimize!(max_flow)


