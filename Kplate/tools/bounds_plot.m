function bounds_plot(data_table, component)
% data_table: a table with columns: name, ss_upp_bounds, ss_low_bounds, ss, ss_std
% component: must be 'ss' or 'ds'

    if nargin < 2 || ~(strcmp(component, 'ss') || strcmp(component, 'ds'))
        error('Component must be ''ss'' or ''ds''');
    end

    switch component
        case 'ss'
            upper_vals = data_table.ss_upp_bounds;
            lower_vals = data_table.ss_low_bounds;
            mean_vals  = data_table.ss;
            std_vals   = data_table.ss_std;
            comp_name = 'Strike-slip Rates';
            x_max = 12;
            x_min = -26;
            pos_name = ' Right Lateral';
            neg_name = ' Left Lateral';
        case 'ds'
            upper_vals = data_table.ds_upp_bounds;
            lower_vals = data_table.ds_low_bounds;
            mean_vals  = data_table.ds;
            std_vals   = data_table.ds_std;
            comp_name = 'Dip-slip Rates';
            x_max = 26;
            x_min = -2;
            pos_name = ' Reverse Fault';
            neg_name = ' Normal Fault';
    end

    names = data_table.faults;
    y = 1:size(data_table, 1);
    height = 0.6;

    % Define cold-warm academic colors (Nature/Science style)
    color_positive = [157, 195, 231] / 255;  % soft blue
    color_negative = [239, 122, 109] / 255;  % soft red
    color_special  = [210, 210, 210] / 255;  % soft gray

    figure('Position', [10 10 700 1300]); hold on

    xline(0, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 2);
    h_positive = [];  % for legend
    h_negative = [];  % for legend

    % Plot horizontal bars using rectangles
    switch component
        case 'ss'
            for i = 1:length(y)
                left = lower_vals(i);
                width_i = upper_vals(i) - lower_vals(i);

                if lower_vals(i) == 0
                    face_col = color_positive;
                elseif upper_vals(i) == 0
                    face_col = color_negative;
                else
                    face_col = color_special;
                end

                r = rectangle('Position', [left, y(i)-height/2, width_i, height], ...
                             'FaceColor', face_col, 'EdgeColor', 'k');
                r.FaceAlpha = 0.3;

                if isempty(h_positive)
                    h_positive = r;
                end
            end
            errorbar(mean_vals, y, std_vals, 'horizontal', 'k.', 'LineWidth', 1.5, 'CapSize', 5)
            scatter(mean_vals, y, 40, 'k', 'filled')  % mean points

            % Create dummy patches for legend
            p1 = patch(NaN, NaN, color_positive, 'FaceAlpha', 0.6, 'EdgeColor', 'k', 'DisplayName', pos_name);
            p2 = patch(NaN, NaN, color_negative, 'FaceAlpha', 0.6, 'EdgeColor', 'k', 'DisplayName', neg_name);
            p3 = patch(NaN, NaN, color_special,  'FaceAlpha', 0.6, 'EdgeColor', 'k', 'DisplayName', ' No Prior');
            lgd = legend([p1, p2, p3], 'Location', 'northwest');

        case 'ds'
            for i = 1:length(y)
                left = lower_vals(i);
                width_i = upper_vals(i) - lower_vals(i);

                % Set bar color and draw
                if upper_vals(i) < 0 || lower_vals(i) < 0
                    face_col = color_negative;
                    r = rectangle('Position', [0, y(i)-height/2, width_i, height], ...
                             'FaceColor', face_col, 'EdgeColor', 'k');
                else
                    face_col = color_positive;
                    r = rectangle('Position', [left, y(i)-height/2, width_i, height], ...
                             'FaceColor', face_col, 'EdgeColor', 'k');
                end

                r.FaceAlpha = 0.3;

                if upper_vals(i) < 0 || lower_vals(i) < 0
                    if isempty(h_negative)
                        h_negative = r;
                    end
                else
                    if isempty(h_positive)
                        h_positive = r;
                    end
                end
            end
            errorbar(abs(mean_vals), y, std_vals, 'horizontal', 'k.', 'LineWidth', 1.5, 'CapSize', 5)
            scatter(abs(mean_vals), y, 40, 'k', 'filled')  % mean points

            % Create dummy patches for legend
            p1 = patch(NaN, NaN, color_positive, 'FaceAlpha', 0.6, 'EdgeColor', 'k', 'DisplayName', pos_name);
            p2 = patch(NaN, NaN, color_negative, 'FaceAlpha', 0.6, 'EdgeColor', 'k', 'DisplayName', neg_name);
            lgd = legend([p1, p2], 'Location', 'northeast');
    end

    ylim([0.3, length(y)+0.7])
    xlim([x_min, x_max])
    yticks(y)
    yticklabels(names)
    xlabel('Slip Rate (mm/yr)')
    title(sprintf('%s', comp_name))
    box on
    set(gca, 'FontSize', 14, 'LineWidth', 1);
    grid on
    lgd.FontSize = 12;
    lgd.ItemTokenSize = [20, 10];
end
