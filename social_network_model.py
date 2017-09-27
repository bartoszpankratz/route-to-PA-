
import random
import operator
import networkx as nx

class inhabitant ():
    def __init__(self, world):
        self.world = world
        self.parameters = self.get_parameters()
        self.number_of_friends = self.world.number_of_friends
        self.distances = {}
        self.opinion = round(random.random())
        self.internal_motivation = random.random() 
        self.active = 0
             
    
    def get_parameters(self):
        age = (random.randint(18,80) -18) / (80 - 18)
        wage = (random.uniform(1200,50000) - 1200) / (50000 - 1200)
        educ = (random.randint(1,6) - 1) / (6 - 1)
        return (age,wage,educ)
    
        
    def create_network(self):
        self.network = {}
        for i in range(len(self.neighbors)):
            if self.world.graph.node[self.neighbors[i]] != self:
                distance = 0
                for j in range(len(self.parameters)):
                    distance += (self.parameters[j] - self.world.graph.node[self.neighbors[i]].parameters[j])**2
                self.network[self.world.graph.node[self.neighbors[i]]] = distance**0.5
        
    def is_active (self):
        if self.active == 0:
            active_friends = 0
            for i in self.network:
                if i.active > 0:
                    active_friends += 1
            external_motivation = -(1 - active_friends/len(self.network))
            if self.internal_motivation + external_motivation > 0:
                self.active = 1
                self.world.final_event = 0
                
    def change_opinion (self):
        own_opinion = self.internal_motivation
        opposite_opinion = 0
        for i in self.network:
            if i.opinion == self.opinion:
                own_opinion += i.internal_motivation * (1 - self.network.get(i))
            else:
                opposite_opinion += i.internal_motivation * (1 - self.network.get(i))
        if opposite_opinion > own_opinion:
            self.world.final_event = 0
            if self.opinion == 1:
                self.opinion = 0
            else:
                self.opinion = 1
        

class world ():
    def __init__ (self,number_agents, number_of_friends, percent_active, max_iter):
        self.number_agents = number_agents
        self.number_of_friends = number_of_friends
        self.population = []
        self.graph = nx.newman_watts_strogatz_graph(self.number_agents, self.number_of_friends, 0)
        self.percent_active = percent_active
        self.max_iter = max_iter
        
    def generate_population(self):
        for i in range(self.number_agents):
            self.population.append(inhabitant(self))
            self.graph.node[i] = self.population[i]
            self.population[i].neighbors = self.graph.neighbors(i)
        #self.population.sort(key=lambda x: x.number_of_friends)
 
    def initialize(self):
        self.generate_population()
        for i in range(self.number_agents):
            self.population[i].create_network()
        volunteers = random.sample(self.population, round(self.number_agents * self.percent_active))
        for i in range(len(volunteers)):
            volunteers[i].active = 1
            
    def run(self):
        no_of_participants = 0
        tick = 0
        self.opinion_changed = 0
        while tick < self.max_iter:
            self.final_event = 1
            for i in range(self.number_agents):
                self.population[i].is_active()
                self.population[i].change_opinion()
            tick += 1
            if self.final_event == 1:
                break 
        for i in range(self.number_agents):
            if self.population[i].active == 1:
                no_of_participants += 1 
        return no_of_participants, tick

        

a = world(10000, 100, 0.01, 10000)
a.initialize()
a.run()
