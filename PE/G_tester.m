clear; clc

%%

number_of_objectives = 2;
number_of_inputs = 3;
number_of_membership_functions = 5;
number_of_rules = number_of_membership_functions ^ number_of_inputs;

num_of_angle = 10;
angle_list = linspace(0, pi/2, num_of_angle);

%%

dimension = 50;
%%

Fuzzy_critic.input_number = number_of_inputs;
Fuzzy_critic.weights = zeros(number_of_rules , 1);
Fuzzy_critic.membership_fun_number = number_of_membership_functions;
Fuzzy_critic.input_bounds = [0 dimension;0 dimension;-pi pi];

Fuzzy_test.input_number = number_of_inputs;
Fuzzy_test.weights = zeros(number_of_rules , 1);
Fuzzy_test.membership_fun_number = number_of_membership_functions;
Fuzzy_test.input_bounds = [0 dimension;0 dimension;-pi pi];
%%

critic.pareto = 0 * ones ( 1 , number_of_objectives);
critic.minimum_pareto = 0 * ones ( 1 , number_of_objectives);
critic = repmat (critic , number_of_rules , 1);

critic(51).pareto = [cos(linspace(0, pi/2,20))' + 0, sin(linspace(0, pi/2,20))' - 1];
critic(76).pareto = [cos(linspace(0, pi/2,20))' + 1, sin(linspace(0, pi/2,20))' - 2];
critic(56).pareto = [cos(linspace(0, pi/2,20))' + 2, sin(linspace(0, pi/2,20))' - 3];
critic(81).pareto = [cos(linspace(0, pi/2,20))' + 3, sin(linspace(0, pi/2,20))' - 4];
critic(52).pareto = [cos(linspace(0, pi/2,20))' + 4, sin(linspace(0, pi/2,20))' - 5];
critic(77).pareto = [cos(linspace(0, pi/2,20))' + 0, sin(linspace(0, pi/2,20))' - 1];
critic(57).pareto = [cos(linspace(0, pi/2,20))' + 1, sin(linspace(0, pi/2,20))' - 2];
critic(82).pareto = [cos(linspace(0, pi/2,20))' + 0, sin(linspace(0, pi/2,20))' - 1];

for i = 1:number_of_rules

    critic(i).minimum_pareto = min(critic(i).pareto,[],1);

end
%%

position_agent = [0 0 pi/4;0 0 pi/4];

iteration = 1;

Fuzzy_test.weights = zeros (number_of_rules , 1);
active_rules_2 = fuzzy_engine_3 ([position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_test);

%%

matrix_G = G_extractor (critic , active_rules_2 , angle_list);

V_s_2 = zeros (num_of_angle, number_of_objectives);

for j = 1 : num_of_angle

    Fuzzy_critic.weights = zeros (number_of_rules , 1);

    Fuzzy_critic.weights(active_rules_2.act , 1) = squeeze(matrix_G(j,1,:))';

    V_s_2 (j, 1) = fuzzy_engine_3 ( [position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_critic ).res;

    Fuzzy_critic.weights = zeros (number_of_rules , 1);

    Fuzzy_critic.weights(active_rules_2.act , 1) = squeeze(matrix_G(j,2,:))';

    V_s_2 (j, 2) = fuzzy_engine_3 ( [position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_critic ).res;

end