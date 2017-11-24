
using Distributions, LightGraphs

dist = Normal(0.25,0.3); #distribution from which agent's motivations to participate are drawn
n_nodes = 200; #number of agents in model
n_edges = 50; #number of edges in watts-strogatz model
rew_prob = 0.09; #rewiring probability of graph
max_iter = 1000;
per_volunteers = 0.1; #percent of agents active at the begining
params = readcsv("C:/Users/P/Downloads/dataset.txt"); #a dataset whith parameters used in a model
params = params[2:end,:];


#type describing each agent
mutable struct inhabitant
    opinion::Int64 #opinion of agents about the topic, right now it is a random number but probably I will use a data from a questionnaire
    internal_motivation::Float64 #agent's internal motivation to act; sum of the predicted participation probability and random number
    active::Int64 #indicate whether agent participate or not
    parameters::Vector #demographical parameters describing each agent 
end   

#fuction calculating a Gowen's distances between agents, it might be useful for sorting agents or analyzing results
function gowen_distances(agent, agents)
    distances = []
    for a in agents
        if a != agent
            append!(distances,mean(abs(agent.parameters[i] - a.parameters[i]) for i = 1:length(agent.parameters)))
        end
    end
    return distances
end

#here the parameters describing population are created
function generate_parameters(n_nodes,params)
    #here the parameters for all agents are sampled
    parameters = params[rand(1:end,n_nodes), :]
    
    #income is on the interval scale; this part transform it into continous variable
    income = [Uniform(0,10_000),Uniform(10_000,20_000),Uniform(20_000,30_000), Uniform(30_000,40_000),Uniform(40_000,50_000),
    Uniform(50_000,60_000), Uniform(60_000,75_000), Uniform(75_000,100_000), Uniform(100_000,150_000),
    Uniform(150_000,250_000), Uniform(250_000, 500_000), Uniform(500_000, 2_000_000)]
    
    
    
    inc = [rand(income[parameters[i,1]]) for i = 1:n_nodes]
    #########
    
    #then all variables are normalize
    min_inc = minimum(inc)
    max_inc = maximum(inc) 
    
    min_age = minimum(parameters[:,2])
    max_age = maximum(parameters[:,2])
    
    min_educ = minimum(parameters[:,3])
    max_educ = maximum(parameters[:,3])
    
    inc = [(j - min_inc)/(max_inc - min_inc) for j in inc]
    age = [(parameters[i,2] - min_age) /(max_age - min_age) for i = 1:n_nodes]
    educ = [(parameters[i,3] - min_educ) /(max_educ - min_educ) for i = 1:n_nodes]
    ######
    return hcat(inc,age,educ,parameters[:,5])
        
end

#this function generate agents and graph describing  social network
function generate_network(n_nodes, n_edges, rew_prob, params)
    parameters =  generate_parameters(n_nodes,params)
    
    inhabitants = [inhabitant(rand([0,1]),(parameters[i,4] + rand(dist)),0, parameters[i,1:3]) for i = 1:n_nodes]
    
    ### tu nie wiem czy to w ogole zachowam w koncowej symulacji, zalezy czy zdaze wymyslic rozsadny algortytm sortowania -
    #chodzi o to zeby podobni sobie agenci ze soba 
    #sasiadowali i tworzyli klastry
    sort!(inhabitants, by = i -> mean(i.parameters))
    inhabitants_even = [inhabitants[i] for i = 1:length(inhabitants) if mod(i,2) == 1 ]
    inhabitants_odds = [inhabitants[i] for i = 1:length(inhabitants) if mod(i,2) == 0 ]
    sort!(inhabitants_odds, by = i -> mean(i.parameters), rev = true)
    inhabitants = vcat(inhabitants_even,inhabitants_odds)
    #########
                            
    graph = watts_strogatz(n_nodes, n_edges, rew_prob)
    return inhabitants, graph
end

function initialize(n_nodes, n_edges, rew_prob,per_volunteers,params)
    agents, network = generate_network(n_nodes, n_edges, rew_prob,params) 
    for i = 1:n_nodes  #each agent with the motivation higher than 1 became active
        if agents[i].internal_motivation >= 1 
            agents[i].active = 1
        end
        
    end
    volunteers = rand(agents,Int(round(per_volunteers*n_nodes))) #some agents are randomly selected to be active at the begining of the simulation
    for j in volunteers
        j.active = 1
    end
    return agents, network
end

function is_active(inhabitants, graph)
    final_event = true
    # here is the main part of the simulation; in every iteration an internal motivation to participate of each agent
    #is compared with the number of his active neighbors; if this sum is higher than 0 agent is encouraged to participate
	#and became active
    for i = 1:length(inhabitants)
        if inhabitants[i].active == 0
           external_motivation = - (1 - sum(inhabitants[j].active  for j in neighbors(graph,i)) / length(neighbors(graph,i)))
           if inhabitants[i].internal_motivation  + external_motivation > 0
                inhabitants[i].active = 1
                final_event = false
            end
        end
    end
    return final_event
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
    #na razie symulacja zwraca to ilu agentow bylo aktywnych od poczatku a ilu bylo aktywnych na koncu, 
    #docelowo beda to rozne parametry pozwalajace na porownanie aktywnych i nieaktywnych agentow
    return active_beginning/n_nodes, active_end/n_nodes 
end

@time run_simulation(10000,12,0.09,0.1,params,3000)




