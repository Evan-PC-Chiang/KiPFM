function print_axes_info()
% 顯示當前 axes (gca) 的位置、實際像素大小、邊界等資訊

    ax = gca;
    fig = gcf;

    % 圖框相對位置（單位：比例）
    ax_pos = get(ax, 'Position');
    fprintf('📐 Axes Position (normalized): [left %.2f, bottom %.2f, width %.2f, height %.2f]\n', ...
        ax_pos(1), ax_pos(2), ax_pos(3), ax_pos(4));

    % 圖窗實際像素大小
    fig_pos = get(fig, 'Position');
    fig_width  = fig_pos(3);
    fig_height = fig_pos(4);

    % 換算成像素單位
    ax_width_px  = ax_pos(3) * fig_width;
    ax_height_px = ax_pos(4) * fig_height;
    fprintf('📏 Axes Size (pixels): %.1f × %.1f px\n', ax_width_px, ax_height_px);

    % 額外邊界空間
    ti = get(ax, 'TightInset');
    fprintf('📦 TightInset: left %.2f, bottom %.2f, right %.2f, top %.2f (normalized)\n', ...
        ti(1), ti(2), ti(3), ti(4));
end