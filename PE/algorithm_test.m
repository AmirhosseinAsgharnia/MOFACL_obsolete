function algorithm_test (Fuzzy_actor , episode , gama_data , i)

max_iteration = 2000;

step_time = .1;

capture_radius = 3;

position_agent = zeros (max_iteration , 3);

position_agent (1 , :) = [0 , 0 , pi/4];

iteration = 0;

terminate = 0;

while ~terminate && iteration < max_iteration

    iteration = iteration + 1;

    %% input calculator

    u = fuzzy_engine_3 ([position_agent(iteration , 1) , position_agent(iteration , 2) , position_agent(iteration , 3)] , Fuzzy_actor);

    %%

    p = ode4(@(t , y) agent(t , y , u.res , gama_data.speed) , [0 step_time] , position_agent(iteration , :));

    position_agent(iteration + 1 , :) = p(end , :);

    position_agent(iteration + 1 , 3) = ang_adj(position_agent(iteration + 1 , 3));

    position_agent = border(position_agent , iteration);

    terminate = termination (iteration , capture_radius , position_agent , gama_data.position_goal , gama_data.position_pit);

end

if terminate == 1
    position_agent ( iteration + 2 : end , :) = [];
end

fig = figure('Visible','off');

set(fig, ...
    'Units',        'inches', ...
    'Position',     [0 0 5 5], ...
    'PaperUnits',   'inches', ...
    'PaperPosition',[0 0 5 5] ...
    );

plot([0 0 gama_data.dimension gama_data.dimension 0],[0 gama_data.dimension gama_data.dimension 0 0],'--k')
hold on
plot(gama_data.position_pit(1),gama_data.position_pit(2),'or')
plot(gama_data.position_goal(1),gama_data.position_goal(2),'og')

plot(position_agent(:,1) , position_agent(:,2))

xlim([-10 60]);
ylim([-10 60]);

grid on
grid minor

print(fig, sprintf('Figs/Episode_%d_i_%d.png',episode,i), '-dpng', '-r300');

close(fig)
