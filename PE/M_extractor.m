function matrix_M = M_extractor (critic , active_rules , angle , angle_list)

matrix_M = zeros(numel(angle_list) , 2 , numel(active_rules.act));

for rule = active_rules.act'

    origin = critic (rule) . minimum_members;

    for i = 1:numel(angle_list)

        D = abs ( (critic (rule) . members (: , 1) - origin (1) ) * sin (angle_list(angle)) - (critic (rule) . members (: , 2) - origin (2) ) * cos (angle_list(angle)) );

        [~ , members_select] = min(D);

        matrix_M (i , : , rule) = critic (rule) . members (members_select , :);

    end

end
