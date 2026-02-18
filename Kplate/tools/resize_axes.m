function resize_axes(fig_size, ax_size)
% resize_axes([fig_w, fig_h], [ax_w, ax_h])
% Resize current figure and axes to specified pixel sizes, centered

    % Set figure size in pixels
    set(gcf, 'Units', 'pixels', 'Position', [100, 100, fig_size(1), fig_size(2)]);

    % Compute centered axes position
    ax_left = (fig_size(1) - ax_size(1)) / 2;
    ax_bot  = (fig_size(2) - ax_size(2)) / 2;

    % Apply to current axes
    set(gca, 'Units', 'pixels', 'Position', [ax_left, ax_bot, ax_size(1), ax_size(2)]);

    % Optional visual tuning
    set(gca, 'FontSize', 12, 'LineWidth', 1.2)
    box on; grid on

    % Print result (for debug)
    fprintf('✅ Figure resized to [%d x %d], Axes resized to [%d x %d] px\n', ...
        fig_size(1), fig_size(2), ax_size(1), ax_size(2));
end
