using JuMP
using HiGHS

G = [
    0  6  4  9  0  0  0  0;  # r
    0  0  2  0  3  0  0  0;  # p
    0  1  0  0  2  0  6  0;  # q
    0  0  0  0  0  8  1  0;  # a
    0  0  0  1  0  0  0  8;  # b
    0  0  1  0  2  0  0  4;  # c
    0  0  0  0  0  1  0  6;  # d
    0  0  0  0  0  0  0  0;  # s
]

n = size(G, 1)


max_flow = Model(HiGHS.Optimizer)

@variable(max_flow, f[1:n, 1:n] >= 0)

@constraint(max_flow, [i = 1:n, j = 1:n], f[i, j] <= G[i, j])

@constraint(max_flow, [i = 2:n-1], sum(f[i, :]) == sum(f[:, i]))

@objective(max_flow, Max, sum(f[1, :]))

optimize!(max_flow)