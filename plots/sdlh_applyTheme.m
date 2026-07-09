function sdlh_applyTheme(fig, opts)
%SDLH_APPLYTHEME Apply base custom theme to figures.
%
%   sdlh_applyTheme() styles the current figure (gcf) with defaults.
%   sdlh_applyTheme(fig) styles a specific figure handle.
%   sdlh_applyTheme(fig, 'FontSize', 11, 'GridOn', true) overrides
%   individual theme properties.
%
%   Name-value options:
%     FontName   - default "CMU Serif"
%     FontSize   - default 10
%     AxesWidth  - default 0.75   (axes border line width)
%     Box        - "on"/"off"     default "off"
%     GridOn     - true/false     default true
%     ColorOrder - Nx3 matrix or [] to leave default, default []
%     LegendBox  - "on"/"off"     default "on"
%
%   Example:
%     figure; plot(x, y); legend('signal');
%     sdlh_applyTheme(); % Apply default style
%
%     figure; plot(x, y);
%     sdlh_applyTheme(gcf, 'GridOn', true, 'FontSize', 11);

arguments
    fig (1,1) matlab.ui.Figure = gcf
    opts.FontName (1,1) string = "CMU Serif"
    opts.FontSize (1,1) double = 10
    opts.LineWidth (1,1) double = 1
    opts.AxesWidth (1,1) double = 0.75
    opts.Box (1,1) string {mustBeMember(opts.Box, ["on","off"])} = "off"
    opts.GridOn (1,1) logical = true
    opts.ColorOrder double = []
    opts.LegendBox (1,1) string {mustBeMember(opts.LegendBox, ["on","off"])} = "on"
end

fig.Color = 'w';

axesList = findall(fig, 'Type', 'axes');
for k = 1:numel(axesList)
    ax = axesList(k);
    ax.FontName   = opts.FontName;
    ax.FontSize   = opts.FontSize;
    ax.LineWidth  = opts.AxesWidth; 
    ax.Box        = opts.Box;

    if ~isempty(opts.ColorOrder)
        ax.ColorOrder = opts.ColorOrder;
    end
    if opts.GridOn                  
        ax.GridLineStyle = ':';
        ax.GridAlpha = 0.3;
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end
end

legList = findall(fig, 'Type', 'legend');
for k = 1:numel(legList)
    legList(k).FontName = opts.FontName;
    legList(k).FontSize = opts.FontSize;
    legList(k).Box = 'on';
end

textList = findall(fig, 'Type', 'text');
for k = 1:numel(textList)
    textList(k).FontName = opts.FontName;
    textList(k).FontSize = opts.FontSize;
end

end
