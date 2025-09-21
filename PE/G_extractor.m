function matrix_G = G_extractor (critic , active_rules , angle_list)

matrix_G = zeros(numel(angle_list) , 2 , numel(active_rules.act));

rule_iterator = 0;

for rule = active_rules.act'

    rule_iterator = rule_iterator + 1;

    origin = critic (rule) . minimum_pareto;

    for i = 1:numel(angle_list)

        D = abs ( (critic (rule) . pareto (: , 1) - origin (1) ) * sin (angle_list(i)) - (critic (rule) . pareto (: , 2) - origin (2) ) * cos (angle_list(i)) );

        [~ , pareto_select] = min(D);

        matrix_G (i , : , rule_iterator) = critic (rule) . pareto (pareto_select , :);

    end

end
