
using Distributions
using LightGraphs, GraphPlot
dist = Normal(0.5,0.25);
n_nodes = 200;
n_edges = 50;
rew_prob = 0.7;
max_iter = 1000;
per_volunteers = 0.1;
params = readcsv("C:/Users/P/Downloads/data.csv");
params = [params[i,:] for i = 2:size(params,1)];

mutable struct inhabitant
    opinion::Int64
    internal_motivation::Float64
    active::Int64
    parameters::Vector
end   

function generate_network(n_nodes, n_edges, rew_prob, params)
    params =  gerate_params(n_nodes,params)
    inhabitants = [inhabitant(rand([0,1]),rand(dist),0, params[i]) for i = 1:n_nodes]
    graph = watts_strogatz(n_nodes, n_edges, rew_prob)
    return inhabitants, graph
end

function gerate_params(n_nodes,params)
    parameters = rand(params,n_nodes)
    
    income = [Uniform(0,10_000),Uniform(10_000,20_000),Uniform(20_000,30_000), Uniform(30_000,40_000),Uniform(40_000,50_000),
    Uniform(50_000,60_000), Uniform(60_000,75_000), Uniform(75_000,100_000), Uniform(100_000,150_000),
    Uniform(150_000,250_000), Uniform(250_000, 500_000), Uniform(500_000, 2_000_000)]
    
    for i = 1:length(parameters)
        inc = rand(income[parameters[i][1]]) 
    end
    return parameters
end

function is_active(inhabitants, graph)
    final_event = true
    for i = 1:length(inhabitants)
        if inhabitants[i].active == 0
           external_motivation = - (1 - sum(inhabitants[j].active  for j in neighbors(graph,i)) / length(neighbors(graph,i)))
           if inhabitants[i].internal_motivation + external_motivation > 0
                inhabitants[i].active = 1
                final_event = false
            end
        end
    end
    return final_event
end

function initialize(n_nodes, n_edges, rew_prob,per_volunteers,params)
    agents, network = generate_network(n_nodes, n_edges, rew_prob,params)
    for i = 1:n_nodes
        if agents[i].internal_motivation >= 1 
            agents[i].active = 1
        end
        
    end
    volunteers = rand(agents,Int(round(per_volunteers*n_nodes)))
    for j in volunteers
        j.active = 1
    end
    return agents, network
end

function run_simulation(n_nodes, n_edges, rew_prob, per_volunteers, params,max_iter)
    agents, network = initialize(n_nodes, n_edges, rew_prob, per_volunteers,params)
    active_beginning = sum(j.active  for j in agents)
    k = 0
    while true
        done = is_active(agents, network)
    k += 1
    (k > max_iter || done) && break
    end
    active_end = sum(j.active  for j in agents)
    return active_beginning / n_nodes, active_end / n_nodes
end

@time run_simulation(1000,12,0.09,0.1,params,3000)
