

function Arrival_rate(T_a)
    return 1/T_a
end

function Processing_rate(T_p)
    return 1/T_p
end

function Utilization(lambda, mu,N)
    return lambda/(mu*N)
end

function Coefficient_of_variation_arrival(lambda, sigma_a)
    return sigma_a*lambda
end

function Coefficient_of_variation_processing(mu, sigma_p)
    return sigma_p*mu
end

function Average_queing_time(c_a, c_p, rho, N, mu)
    return (c_a^2+c_p^2)/2*(rho^(sqrt(2*(N+1))-1))/(N*(1-rho))*1/mu
end

function Average_lead_time(A_Q_time, mu)
    return A_Q_time + 1/mu
end

function Inventory_processing(rho, N)
    return rho*N
end

function Average_length_of_queue(lambda, A_Q_time)
    return lambda*A_Q_time
end

function Total_inventory(lambda, A_Q_time, mu)
    return lambda*(A_Q_time + 1/mu)
end
