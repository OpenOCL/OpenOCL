function oclAnimation(data, ts)
  % data is an array of tuples (handle, type, xvalues, yvalues) where all values have
  % to have the same length, e.g. 
  %   {type:'plot', Xdata:[1,2,3,4,5,6], Ydata:[1.2,1.3,1.2,1.2,1.1,1.0]},...
  %   {type: 'text', String: ['a','b','c','d','e','f']}, {type: 'stairs'... }
  
  % setup figure and plots
  fig = oclFigure;
  handles = cell(length(data), 1);
  
  for k=1:length(data)
    
    plot_data = data{k};
    
    if plot_data.type == plot_types().numeric
      handles{k} = oclPlot(0,0);
    elseif plot_data.type == plot_types.stairs
      handles{k} = oclStairs(0,0);
    elseif plot_data.type == plot_types.text
      handles{k} = oclText(0,0);
    end
  end
  
  pause(0.5)
  
  for k=1:length(data)
    
    plot_data = data{k};
    if plot_data.type == plot_types().numeric
      
      if isfield(plot_data, 'Xdata')
        set(handles{k}, 'Xdata', plot_data.Xdata);
      end
      
      if isfield(plot_data, 'Ydata')
        set(handles{k}, 'Ydata', plot_data.Ydata);
      end
      
    elseif plot_data.type == plot_types.stairs
      
      if isfield(plot_data, 'Xdata')
        set(handles{k}, 'Xdata', plot_data.Xdata);
      end
      
      if isfield(plot_data, 'Ydata')
        set(handles{k}, 'Ydata', plot_data.Ydata);
      end
      
    elseif plot_data.type == plot_types.text
      
      if isfield(plot_data, 'Xdata')
        set(handles{k}, 'Xdata', plot_data.Xdata);
      end
      
      if isfield(plot_data, 'Ydata')
        set(handles{k}, 'Ydata', plot_data.Ydata);
      end
      
      if isfield(plot_data, 'String')
        set(handles{k}, 'String', plot_data.String);
      end
      
    end
    
    pause(ts)
    
  end
  
  
  
end
