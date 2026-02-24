
using JuMP
using HiGHS

G = [
    0   5    5    9     3    0;      # 1: KBH
    0   0    0    0     0    1;      # 2: Bus6
    0   0    0    0     0    1;      # 3: Bus8
    0   0    0    0     0    4;      # 4: Bus10
    0   0    0    0     0    5;      # 5: Fly
    0   0    0    0     0    0;      # 6: Bornholm
]

n = size(G, 1)

max_flow = Model(HiGHS.Optimizer)

@variable(max_flow, f[1:n, 1:n] >= 0)

@constraint(max_flow, [i = 1:n, j = 1:n], f[i, j] <= G[i, j])

@constraint(max_flow, [i = 2:n-1], sum(f[i, :]) == sum(f[:, i]))

@objective(max_flow, Max, sum(f[1, :]))

optimize!(max_flow)