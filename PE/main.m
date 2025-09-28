clear; clc

rng(112)

mkdir("Figs")

update_inspection = false;
%% simulation time parameters

max_episode = 10000; % maximum times a whole game is played.

test_episode = 20; % each "test_episode" a test without noise is conducted.

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

% actor_learning_rate = 0.01;

critic_learning_rate = 0.1;

discount_factor = 0.0;

num_of_angle = 10;

angle_list = linspace (0 , pi/2 , num_of_angle);

sigma_rand = 1;

%% algorithm parameters

number_of_objectives = 2;

number_of_inputs = 3;

number_of_membership_functions = 5;

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

critic.pareto = 0 * ones ( 1 , number_of_objectives);
critic.minimum_pareto = 0 * ones ( 1 , number_of_objectives);
critic.select = 0;
critic = repmat (critic , number_of_rules , 1);

%% actor spaces

actor.pareto = 0;
actor = repmat (actor , number_of_rules , 1);

%% training loop

test_count = 0;

for episode = 1 : max_episode
    
    % sigma_rand = sigma_rand * 10 ^ (log10(0.2)/max_episode);
    % actor_learning_rate = actor_learning_rate * 10 ^ (log10(0.5)/max_episode);
    % critic_learning_rate = critic_learning_rate * 10 ^ (log10(0.5)/max_episode);

    terminate = 0;
    iteration = 0;

    %% episode simulation

    position_agent = zeros (max_iteration , 3);
    position_agent (1 , :) = [0, 0, pi / 4];

    if update_inspection == true
        fig_play = figure;
        ax_play = axes('Parent', fig_play);  % store axis handle
        set(fig_play, 'units', 'inches', 'pos', [.5 .5 6 6])
        set(fig_play, 'DefaultAxesFontName','Times New Roman')
        set(fig_play, 'DefaultAxesFontSize',9)
        set(fig_play, 'DefaultTextFontName','Times New Roman')
        set(fig_play, 'DefaultTextFontSize',9)
    end

    tic
    
    while ~terminate && iteration < max_iteration

        iteration = iteration + 1;

        if update_inspection == true
            plot(ax_play, position_agent(iteration, 1), position_agent(iteration, 2), '.b'); hold on
            if iteration == 1
                plot(ax_play, position_goal(1) + capture_radius * cos(0:0.01:2*pi), position_goal(2) + capture_radius * sin(0:0.01:2*pi) , '-g')
                plot(ax_play, position_pit(1) + capture_radius * cos(0:0.01:2*pi), position_pit(2) + capture_radius * sin(0:0.01:2*pi) , '-r')
                grid on
            end
            xlim([0 dimension]); ylim([0 dimension])
            axis('square')
        end

        %% fired rules (state s)

        actor_output_parameters = zeros (number_of_rules , 1);

        active_rules_1 = fuzzy_engine_3 ([position_agent(iteration , 1) , position_agent(iteration , 2) , position_agent(iteration , 3)] , Fuzzy_test); % Just to check which rules are going be fired.

        %% pre-processing the rule-base and exploration - exploitation (distance from origin) (ND is applyed before!)
        
        angle = randi([1 num_of_angle]);

        for rule = active_rules_1.act'

            origin = critic (rule) . minimum_pareto;

            D = abs ( (critic (rule) . pareto (: , 1) - origin (1) ) * sin (angle_list(angle)) - (critic (rule) . pareto (: , 2) - origin (2) ) * cos (angle_list(angle)) );

            [~ , select] = min(D);

            critic(rule).select = select;

            actor_output_parameters(rule) = actor(rule).pareto (select);

        end

        %% selecting action

        Fuzzy_actor.weights = actor_output_parameters;

        u = fuzzy_engine_3 ([position_agent(iteration , 1) , position_agent(iteration , 2) , position_agent(iteration , 3)] , Fuzzy_actor);

        up = max( -pi/6 , min ( pi/6 , u.res + randn * sigma_rand));
        % up = max( -pi/6 , min ( pi/6 , u.res + randn * sigma_rand));
        %% taking action

        p = ode4(@(t , y) agent(t , y , up , speed) , [0 step_time] , position_agent(iteration , :));

        position_agent(iteration + 1 , :) = p(end , :);

        position_agent(iteration + 1 , 3) = ang_adj(position_agent(iteration + 1 , 3));

        position_agent = border(position_agent , iteration);

        terminate = termination (iteration , capture_radius , position_agent , position_goal , position_pit);

        %% fired rules (state s')

        Fuzzy_test.weights = zeros (number_of_rules , 1);

        active_rules_2 = fuzzy_engine_3 ([position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_test);
        
        for rule = active_rules_2.act'

            critic(rule).minimum_pareto = min(critic(rule).pareto(:,1:number_of_objectives) , [] , 1);

        end
        %% reward calculation

        [reward_1 , reward_2] = reward_function (iteration , position_agent , position_goal , position_pit);
        
        %% calculating v_{t+1}

        matrix_G = G_extractor (critic , active_rules_2 , angle_list);
        
        V_s = zeros (num_of_angle, number_of_objectives);
        
        for j = 1 : num_of_angle
        
            Fuzzy_critic.weights = zeros (number_of_rules , 1);
        
            Fuzzy_critic.weights(active_rules_2.act , 1) = squeeze(matrix_G(j,1,:))';
        
            V_s (j, 1) = fuzzy_engine_3 ( [position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_critic ).res;
        
            Fuzzy_critic.weights = zeros (number_of_rules , 1);
        
            Fuzzy_critic.weights(active_rules_2.act , 1) = squeeze(matrix_G(j,2,:))';
        
            V_s (j, 2) = fuzzy_engine_3 ( [position_agent(iteration + 1, 1) , position_agent(iteration + 1 , 2) , position_agent(iteration + 1 , 3)] , Fuzzy_critic ).res;
        
        end

        if terminate
            V_s = V_s * 0;
        end

        %% calculating temporal difference (Delta)

        Delta = [reward_1, reward_2] + discount_factor * V_s;
        
        %% updating critic

        if update_inspection == true
            fig = figure;
            set(fig, 'units', 'inches', 'pos', [.5 .5 12 6])
            set(fig, 'DefaultAxesFontName','Times New Roman')
            set(fig, 'DefaultAxesFontSize',9)
            set(fig, 'DefaultTextFontName','Times New Roman')
            set(fig, 'DefaultTextFontSize',9)
        end

        firing_strength_counter = 0;

        for rule = active_rules_1.act'

            critic_1 = critic(rule).pareto;
            
            firing_strength_counter = firing_strength_counter + 1;

            critic(rule).pareto = [(1 - critic_learning_rate) * critic(rule).pareto ;  Delta];
            
            actor(rule).pareto = [actor(rule).pareto ;  up * ones(size(Delta, 1),1) * active_rules_1.phi(firing_strength_counter)];

            [critic(rule).pareto , R] = ND_opt (critic(rule).pareto);
            
            actor(rule).pareto(R == 1) = [];

            critic_2 = critic(rule).pareto;

            [sort_order , ~] = CDE(critic(rule).pareto);
            
            if numel(sort_order) > max_repo_member

                critic(rule).pareto = critic(rule).pareto(sort_order(1:max_repo_member),:);
                actor(rule).pareto = actor(rule).pareto(sort_order(1:max_repo_member),:);

            else

                critic(rule).pareto = critic(rule).pareto(sort_order,:);   
                actor(rule).pareto = actor(rule).pareto(sort_order,:);

            end

            critic(rule).minimum_pareto = min(critic(rule).pareto(:,1:number_of_objectives) ,[] ,1);

            if update_inspection == true
                subplot(2,4,firing_strength_counter)
                plot(critic_1(:,1), critic_1(:,2),'*r'); hold on
                plot(critic_2(:,1), critic_2(:,2),'ob');
                plot(critic_aux(:,1), critic_aux(:,2),'xk');

                legend("C_1","C_2","C_aux")
                grid minor
                title(sprintf("Rule: %d", active_rules_1.act(firing_strength_counter)))

                ylabel("Reward 2"); xlabel("Reward 1")
            end

        end

        if update_inspection == true
            close(fig)
        end
    end
    if update_inspection == true
        close(fig_play)
    end
    simulation_time (episode) = toc;

    fprintf ("--------------------------------------------------------\n");
    fprintf ("Episode = %.0d.\n" , episode );
    fprintf ("The process is %.2f%% completed.\n" , episode * 100 / max_episode);
    fprintf ("Episode training took %.1f seconds.\n" , simulation_time (episode));
    fprintf ("--------------------------------------------------------\n");

    if mod( episode , test_episode ) == 0 || episode == 1

        test_count = test_count + 1;
        fprintf ("--------------------------------------------------------\n");
        fprintf ("Test number %d has been started.\n" , test_count);
        fprintf ("--------------------------------------------------------\n");

        actor_weights = G_test (critic , actor , angle_list);

        Fuzzy_actor.weights = actor_weights;
        algorithm_test (Fuzzy_actor , episode , gama_data );
        save(sprintf("policy.mat" ))

    end

end