clear; clc

rng(124)

% ins_mode = 0;

mkdir("Figs")
%% simulation time parameters

max_episode = 10000; % maximum times a whole game is played.

test_episode = 100; % each "test_episode" a test without noise is conducted.

max_time_horizon = 200; % maximum duration of each epoch.

step_time = .1; % step time. (100 ms)

max_iteration = max_time_horizon / step_time + 1;

simulation_time = zeros (max_episode , 1);

max_repo_member = 10;
%% game parameters

dimension = 50;

speed = 5; % speed of the agent (units/sec)

position_goal = [40 , 40];

position_pit  = [40 , 20];

capture_radius = 3;

gama_data.dimension = dimension;
gama_data.speed = speed;
gama_data.position_goal = position_goal;
gama_data.position_pit = position_pit;
gama_data.capture_radius = capture_radius;

%% hyper parameters

actor_learning_rate = 0.05;

critic_learning_rate = 0.1;

discount_factor = 0.0;

num_of_angle = 2;

angle_list = linspace (0 , pi/2 , num_of_angle);

sigma_rand = 0.5;

%% algorithm parameters

number_of_objectives = 2;

number_of_inputs = 3;

number_of_membership_functions = 7;

number_of_rules = number_of_membership_functions ^ number_of_inputs;

%% fuzzy engine prepration (actor main)

Fuzzy_actor.input_number = number_of_inputs;
Fuzzy_actor.membership_fun_number = number_of_membership_functions;
Fuzzy_actor.input_bounds = [0 dimension;0 dimension;-pi pi];

%% fuzzy engine prepration (actor main)

Fuzzy_critic.input_number = number_of_inputs;
Fuzzy_critic.weights = zeros(number_of_rules , 1);
Fuzzy_critic.membership_fun_number = number_of_membership_functions;
Fuzzy_critic.input_bounds = [0 dimension;0 dimension;-pi pi];

%% fuzzy engine prepration (actor test)

Fuzzy_test.input_number = number_of_inputs;
Fuzzy_test.weights = zeros(number_of_rules , 1);
Fuzzy_test.membership_fun_number = number_of_membership_functions;
Fuzzy_test.input_bounds = [0 dimension;0 dimension;-pi pi];

%% critic spaces

critic.members =0 * ones ( max_repo_member , number_of_objectives);

critic.pareto = 0 * ones ( 1 , number_of_objectives);

critic.index = repmat((1:num_of_angle)' , max_repo_member/num_of_angle , 1);

critic.pareto_index = 0;

critic.minimum_pareto = zeros ( 1 , number_of_objectives);

critic.minimum_members = zeros ( 1 , number_of_objectives);

critic.best_value_index = 1;

critic = repmat (critic , number_of_rules , 1);

%% actor spaces

actor.members = 0*ones ( max_repo_member , 1);

actor.pareto = 0;

actor = repmat (actor , number_of_rules , 1);

%%

for rule = 1 : number_of_rules

    critic(rule).minimum_pareto = min (critic(rule).pareto , [] , 1);
    critic(rule).minimum_members = min (critic(rule).members , [] , 1);

end


%% training loop

test_count = 0;


for episode = 1 : max_episode

    terminate = 0;

    iteration = 0;

    %% episode simulation

    position_agent = zeros (max_iteration , 3);

    if rand < 0.25
        position_agent (1 , :) = [0 0 pi/4];
    elseif rand < 0.5
        position_agent (1 , :) = [0 50 -pi/4];
    elseif rand < 0.75
        position_agent (1 , :) = [50 50 -3*pi/4];
    else
        position_agent (1 , :) = [50 0 3*pi/4];
    end

    tic
    angle = randi ([1 2]);
    % angle = 2;
    while ~terminate && iteration < max_iteration

        iteration = iteration + 1;

        %% fired rules (state s)

        actor_output_parameters = zeros (number_of_rules , 1);

        active_rules_1 = fuzzy_engine_3 ([position_agent(iteration , 1) , position_agent(iteration , 2) , position_agent(iteration , 3)] , Fuzzy_test); % Just to check which rules are going be fired.

        %% pre-processing the rule-base and exploration - exploitation (distance from origin) (ND is applyed before!)

        for rule = active_rules_1.act'

            D = find (critic(rule).index == angle);

            Dist = zeros(numel(D),1);

            for i = 1:size(D,1)

                c1 = proj_compare(critic(rule).members(D(i),:), angle_list(angle), critic(rule).minimum_members);
                Dist(i) = distance_real(c1 , critic(rule).minimum_members);

            end

            if rand > 0.8
                select = randi([1 numel(D)]);
            else
                [~ , select] = max(Dist);
            end

            critic(rule).best_value_index = D (select);

            actor_output_parameters(rule) = actor(rule).members (critic(rule).best_value_index);

        end

        %% selecting action

        Fuzzy_actor.weights = actor_output_parameters;

        u = fuzzy_engine_3 ([position_agent(iteration , 1) , position_agent(iteration , 2) , position_agent(iteration , 3)] , Fuzzy_actor);

        up = u.res + sigma_rand * randn;

        %% taking action

        p = ode4(@(t , y) agent(t , y , up , speed) , [0 step_time] , position_agent(iteration , :));

        position_agent(iteration + 1 , :) = p(end , :);

        position_agent(iteration + 1 , 3) = ang_adj(position_agent(iteration + 1 , 3));

        position_agent = border(position_agent , iteration);

        terminate = termination (iteration , capture_radius , position_agent , position_goal , position_pit);

        % if ins_mode
        %     plot(position_agent(iteration , 1) , position_agent(iteration , 2),'.b')
        %     drawnow
        % end
        %% fired rules (state s')

        Fuzzy_test.weights = zeros (number_of_rules , 1);

        active_rules_2 = fuzzy_engine_3 ([position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_test);

        %% reward calculation

        [reward_1 , reward_2] = reward_function (iteration , position_agent , position_goal , position_pit);

        %% calculating v_{t}

        v_weighted = zeros (numel(active_rules_1.act) , number_of_objectives );

        j = 1;

        for rule = active_rules_1.act'

            v_weighted(j , 1) = critic(rule).members(critic(rule).best_value_index , 1);

            v_weighted(j , 2) = critic(rule).members(critic(rule).best_value_index , 2);

            j = j + 1;

        end

        V_s_1 = zeros (1 , 2);

        Fuzzy_critic.weights = zeros (number_of_rules , 1);

        Fuzzy_critic.weights(active_rules_1.act) = v_weighted (: , 1);

        V_s_1 (1) = fuzzy_engine_3 ( [position_agent(iteration , 1) , position_agent(iteration , 2) , position_agent(iteration , 3)] , Fuzzy_critic ).res;

        Fuzzy_critic.weights(active_rules_1.act) = v_weighted (: , 2);

        V_s_1 (2) = fuzzy_engine_3 ( [position_agent(iteration , 1) , position_agent(iteration , 2) , position_agent(iteration , 3)] , Fuzzy_critic ).res;

        %% calculating v_{t+1}

        matrix_G = G_extractor (critic , active_rules_2 , angle , angle_list);

        V_s_2 = zeros (1 , 2);

        Fuzzy_critic.weights = zeros (number_of_rules , number_of_objectives);

        Fuzzy_critic.weights(active_rules_2.act , 1) = matrix_G (: , 1);

        V_s_2 (1) = fuzzy_engine_3 ( [position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_critic ).res;

        Fuzzy_critic.weights = zeros (number_of_rules , number_of_objectives);

        Fuzzy_critic.weights(active_rules_2.act , 1) = matrix_G (: , 2);

        V_s_2 (2) = fuzzy_engine_3 ( [position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_critic ).res;

        if terminate
            V_s_2 = V_s_2 * 0;
        end
        %% calculating temporal difference (Delta)

        Delta = [reward_1 , reward_2] + discount_factor * V_s_2 - V_s_1;

        %% updating critic

        firing_strength_counter = 0;

        for rule = active_rules_1.act'


            firing_strength_counter = firing_strength_counter + 1;

            critic_1 = critic(rule).members(critic(rule).best_value_index , :);

            critic(rule).members(critic(rule).best_value_index , :) = critic(rule).members(critic(rule).best_value_index,:) + ...
                critic_learning_rate * Delta * active_rules_1.phi(firing_strength_counter);

            critic_2 = critic(rule).members(critic(rule).best_value_index , :);

            % [Actor_Update_Sign,c1,c2] = proj_compare(critic_1, critic_2, angle_list(angle), critic(rule).minimum_members);

            [mag, dir_vec, sign_proj] = proj_on_angle(Delta, angle_list(angle));

            actor(rule).members(critic(rule).best_value_index , :) = actor(rule).members(critic(rule).best_value_index,:) + ...
                actor_learning_rate * sign_proj * (up - u.res) * active_rules_1.phi(firing_strength_counter);

            actor(rule).members(critic(rule).best_value_index , :) = max (actor(rule).members(critic(rule).best_value_index , :) , -pi/6);
            
            actor(rule).members(critic(rule).best_value_index , :) = min (actor(rule).members(critic(rule).best_value_index , :) , +pi/6);


            critic(rule).members = normalizer (critic(rule).members);

            [critic , actor] = nondominant_sorting(critic , actor , rule);
            
            min_par_aux = min (critic(rule).pareto , [] , 1);
            critic(rule).minimum_pareto = [min(min_par_aux(1) , critic(rule).minimum_pareto(1)) , min(min_par_aux(2) , critic(rule).minimum_pareto(2))];
        
            min_mem_aux = min (critic(rule).members , [] , 1);
            critic(rule).minimum_members = [min(min_mem_aux(1) , critic(rule).minimum_members(1)) , min(min_mem_aux(2) , critic(rule).minimum_members(2))];

        end
    end

    simulation_time (episode) = toc;

    fprintf ("--------------------------------------------------------\n");
    fprintf ("Episode = %.0d.\n" , episode );
    fprintf ("The process is %.2f%% completed.\n" , episode * 100 / max_episode);
    fprintf ("Repository has %d members.\n" , 30);
    fprintf ("Episode training took %.1f seconds.\n" , simulation_time (episode));
    fprintf ("--------------------------------------------------------\n");

    if mod( episode , test_episode ) == 0 || episode == 1

        test_count = test_count + 1;
        fprintf ("--------------------------------------------------------\n");
        fprintf ("Test number %d has been started.\n" , test_count);
        fprintf ("--------------------------------------------------------\n");

        actor_weights = G_test (critic , actor , angle_list);

        for i =1:1
            Fuzzy_actor.weights = actor_weights(:,i);
            algorithm_test (Fuzzy_actor , episode , gama_data , i);
        end

        save(sprintf("policy.mat" ))

    end

end