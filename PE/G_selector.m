function critic = G_selector (critic , angle , angle_list)

origin = critic . minimum_pareto;

D = abs ( (critic . pareto (: , 1) - origin (1) ) * sin (angle_list(angle)) - (critic . pareto (: , 2) - origin (2) ) * cos (angle_list(angle)) );

[~ , pareto_select] = min(D);

pareto_index = critic.pareto_index(pareto_select);

critic.best_value_index = find(critic.index == pareto_index);