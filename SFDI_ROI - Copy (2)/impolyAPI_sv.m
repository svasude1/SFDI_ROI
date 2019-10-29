function [h_group,draw_api] = impolyAPI_sv(varargin)

    
  [commonArgs,specificArgs] = roiParseInputs_sv(0,2,varargin,mfilename,{'Closed'});
  
  xy_position_vectors_specified = (nargin > 2) && ...
                                  isnumeric(varargin{2}) && ...
                                  isnumeric(varargin{3});
  
  if xy_position_vectors_specified
      error(message('images:impoly:invalidPosition'))
  end
  
  position              = commonArgs.Position;
  interactive_placement = commonArgs.InteractivePlacement;
  h_parent              = commonArgs.Parent;
  h_axes                = commonArgs.Axes;
  h_fig                 = commonArgs.Fig;
  
  positionConstraintFcn = commonArgs.PositionConstraintFcn;
  if isempty(positionConstraintFcn)
      % constraint_function is used by dragMotion() to give a client the
      % opportunity to constrain where the point can be dragged.
      positionConstraintFcn = identityFcn_sv;
  end

  is_closed = specificArgs.Closed;
     
  try
    h_group = hggroup('Parent', h_parent,'Tag','impoly');
  catch ME
    error(message('images:impoly:noAxesAncestor'))
  end
   
  draw_api = polygonSymbol_sv();
  
  basicPolygonAPI = basicPolygon_sv(h_group,draw_api,positionConstraintFcn);
  
  % Handles to each of the polygon vertices
  h_vertices = {};
  
  % Handle to currently active vertex
  h_active_vertex = [];
  
  % Function scoped variable that keeps track of whether A key is
  % depressed.
  a_down = false;
  
  % Alias functions defined in basicPolygonAPI to shorten calling syntax in
  % impoly.
  setPosition               = basicPolygonAPI.setPosition;
  setConstrainedPosition    = basicPolygonAPI.setConstrainedPosition;
  getPosition               = basicPolygonAPI.getPosition;
  setClosed                 = basicPolygonAPI.setClosed;
  setVisible                = basicPolygonAPI.setVisible;
  updateView                = basicPolygonAPI.updateView;
  addNewPositionCallback    = basicPolygonAPI.addNewPositionCallback;
  deletePolygon             = basicPolygonAPI.delete;
 
  if interactive_placement
  	  setClosed(false);
      setVisible(true);

      % Create listener for changes to the active MATLAB figure ui mode. If
      % a figure mode becomes active during interactive placement, we stop
      % the "active" line segment animation
      animate_id = [];
      fig_mode_manager = uigetmodemanager(h_fig);
      
      if isobject(fig_mode_manager)
          mode_listener = event.proplistener(fig_mode_manager,fig_mode_manager.findprop('CurrentMode'),...
              'PostSet',@newFigureMode); %#ok<NASGU>
      else
          mode_listener = iptui.iptaddlistener(fig_mode_manager,...
             'CurrentMode','PostSet',@newFigureMode); %#ok<NASGU>
      end
            
  	  animate_id(end+1) = iptaddcallback(h_fig,'WindowButtonMotionFcn',@animateLine);
      placement_aborted = manageInteractivePlacement_sv(h_axes,h_group,@placePolygon,@buttonUpPlacement);
      for cb_id = 1:numel(animate_id)
          iptremovecallback(h_fig,'WindowButtonMotionFcn',...
              animate_id(cb_id));
      end
      clear mode_listener;
      if placement_aborted
          h_group = [];
          return;
      end
  else
      % Create vertices in initial locations specified by user.    
      setPosition(position);
      createVertices();
  end
  
  setClosed(is_closed);
  setVisible(true);
  draw_api.pointerManagePolygon(true);
  
  % Create context menu for polygon body and vertices once initial placement
  % of polygon is complete. Create context menus after possible
  % buttonUp event during interactive placement to avoid posting context
  % menus during right click interactive placement gestures.
  
  % setColor called within createROIContextMenu requires that cmenu_poly is
  % an initialized variable.
  cmenu_poly =[];
  cmenu_vertices = [];
  
  % Cache current color so that color of new vertices can be kept in sync
  % with tool as they are added.
  current_color = [];
    
  cmenu_poly     = createROIContextMenu_sv(h_fig,getPosition,@setColor);
  setContextMenu(cmenu_poly);
 
  cmenu_vertices = createVertexContextMenu_sv();
  setVertexContextMenu(cmenu_vertices);
    
  addlistener(h_group,'ObjectBeingDestroyed',@cleanUpPolygon);
  
  % Wire new position callback to update vertex position whenever position
  % matrix of polygon changes
  addNewPositionCallback(@updateVertexPositions);
  
  % Wire callbacks to provide A+click gesture to insert new vertices
  % Cache listeners in hggroup so that listeners on parent figure events
  % will be consumed automatically when hggroup is destroyed.
  buttonDownEvent = event.listener(h_fig,'WindowMousePress',@aClickInsert);
  keyDownEvent = event.listener(h_fig,'WindowKeyPress',@aDown);
  keyUpEvent = event.listener(h_fig,'WindowKeyRelease',@aUp);
  setappdata(h_group,'insertNewVertexEvents',[buttonDownEvent,keyDownEvent,keyUpEvent]);
      
  % Define API
  api.setPosition               = setPosition;
  api.setConstrainedPosition    = setConstrainedPosition;
  api.getPosition               = getPosition;
  api.setClosed                 = setClosed;
  api.addNewPositionCallback    = addNewPositionCallback;
  api.delete                    = deletePolygon;
  api.setVerticesDraggable      = draw_api.showVertices;
  api.removeNewPositionCallback = basicPolygonAPI.removeNewPositionCallback;
  api.getPositionConstraintFcn  = basicPolygonAPI.getPositionConstraintFcn;
  api.setPositionConstraintFcn  = basicPolygonAPI.setPositionConstraintFcn;
  api.setColor                  = @setColor;
  
  % Undocumented API methods.
  api.setContextMenu       = @setContextMenu;
  api.getContextMenu       = @getContextMenu;
  api.setVertexContextMenu = @setVertexContextMenu;
  api.getVertexContextMenu = @getVertexContextMenu;
  
  iptsetapi_sv(h_group,api);
  
  updateView(getPosition());
      
    %----------------------------
    function aDown(h_fig,evt) %#ok<INUSL>
       
        if strcmp(evt.Key,'a');
            a_down = true;
        end
        
    end


    %--------------------------
    function aUp(h_fig,evt) %#ok<INUSL>
        
        if strcmp(evt.Key,'a');
            a_down = false;
        end
        
    end
  
    %------------------------------------------
    function aClickInsert(h_fig,evt)
  
        if ~a_down
            return;
        end
           
        h_hit = evt.HitObject;
               
        hit_line = strcmp(get(h_hit,'type'),'line') && ...
            (ancestor(h_hit,'hggroup') == h_group);
        
        if hit_line
            x_line = getXData(h_hit);
            y_line = getYData(h_hit);
            
            if isscalar(x_line)
                x_line = [x_line x_line];
            end
            
            if isscalar(y_line)
                y_line = [y_line y_line];
            end
            
            new_ind = getInsertVertex(x_line,y_line);
            [x_pos,y_pos] = getCurrentPoint_sv(h_axes);
            mouse_pos = [x_pos,y_pos];
            insertPos = getPositionOnLine(x_line,y_line,mouse_pos);
                       
            addVertex(insertPos,new_ind);
            setVertexContextMenu(cmenu_vertices);
            setContextMenu(cmenu_poly);
            setVertexPointerBehavior();
            setColor(current_color);
               
        end
        
        %------------------------------------------------
        function new_ind = getInsertVertex(x_line,y_line)
            
            vert1 = repmat([x_line(1) y_line(1)],getNumVert(),1);
            vert2 = repmat([x_line(2) y_line(2)],getNumVert(),1);
            
            ind1 = find(all(vert1 == getPosition(),2));
            ind2 = find(all(vert2 == getPosition(),2));
            
            duplicate_vertices = length(ind1) > 1 || length(ind2) > 1;
            if duplicate_vertices
                
                found_ind = false;
                for i = 1:length(ind1)
                    if found_ind
                        break;
                    end
                    
                    for j = 1:length(ind2)
                        % In the case of duplicate vertices, choose the set
                        % of vertices that are correctly directly. Direct
                        % connection means being spaced one row apart in
                        % the position matrix.
                        between_first_and_last = abs(ind1(i) - ind2(j)) == getNumVert()-1;
                        spaced_one_apart = (abs(ind1(i) - ind2(j)) == 1)||...
                                           between_first_and_last;
                                       
                        if  spaced_one_apart
                            ind1 = ind1(i);
                            ind2 = ind2(j);
                            found_ind = true;
                            break;
                        end
                        
                    end
                    
                end
                
            end
                        
            between_first_and_last = any([ind1 ind2] == getNumVert()) &&...
                                     any([ind1 ind2] == 1);
            
            if between_first_and_last
                new_ind = getNumVert()+1;
            else
                new_ind = min([ind1,ind2])+1;
            end
            
        end
        
        %--------------------------------------------------------------
        function insertPos = getPositionOnLine(x_line,y_line,mouse_pos)
         % Interactive polygon addition picks the closest point that lies
         % exactly along the line between two vertices. Since the perimter
         % line has width associated with it, the location where button
         % down occurs along the line has to be tuned slightly.
            
            %v1 is vector along polygon line segment
            v1 = [diff(x_line),diff(y_line)];
            
            % v2 is a vector from vertex to current mouse position
            v2 = [mouse_pos(1)-x_line(1),mouse_pos(2)-y_line(1)];
            
            %project parallel portion of v2 onto v1 to find point where
            %perpendicular bisector of current point to line segment connects
            insertPos = (dot(v1,v2)./dot(v1,v1)).*v1 +[x_line(1) y_line(1)];
   
        end
        
    end
  
    %-----------------------
    function setColor(color)
        if ishghandle(getContextMenu())
            updateColorContextMenu_sv(getVertexContextMenu(),color);
            updateColorContextMenu_sv(getContextMenu(),color);
        end
        draw_api.setColor(color);
        current_color = color;
    end

    %----------------------------- 
    function setContextMenu(cmenu_new)
      
       cmenu_obj = findobj(h_group,'Type','line','-or','Type','patch');  
       set(cmenu_obj,'uicontextmenu',cmenu_new);
       
       cmenu_poly = cmenu_new;
        
    end
    
    %-------------------------------------
    function context_menu = getContextMenu
       
        context_menu = cmenu_poly;
    
    end
  
    %-----------------------------------
    function setVertexContextMenu(cmenu_new)
       
        for i = 1:getNumVert()
           set(getVertexHGGroup(h_vertices{i}),'UIContextMenu',cmenu_new); 
        end
        
        cmenu_vertices = cmenu_new;
          
    end

    %-------------------------------------------
    function vertex_cmenu = getVertexContextMenu
    
        % All of the vertices in the polygon shares the same UIContextMenu
        % object. Obtain the shared uicontextmenu from the first vertex in
        % the polygon.
        vertex_cmenu = get(getVertexHGGroup(h_vertices{1}),'UIContextMenu');
        
    end
        
    %--------------------------------
    function cleanUpPolygon(varargin)
       
            deleteContextMenu();
                        
            %Remove callbacks added to listen for key press for cursor
            %management.
            draw_api.unwireShiftKeyPointAffordance(); 
        
    end

    %------------------------- 
    function deleteContextMenu
        if ishghandle(cmenu_poly)
            delete([cmenu_poly,cmenu_vertices]);
        end
        
    end

    %------------------------------
    function newFigureMode(obj,evt) %#ok<INUSL>
        % disable line animation when we have an active mode
        
        modeManager = get(evt.AffectedObject);
        if isempty(modeManager.CurrentMode)
            animate_id(end+1) = iptaddcallback(h_fig,...
                'WindowButtonMotionFcn',@animateLine);
        else
            for i = 1:numel(animate_id)
                iptremovecallback(h_fig,'WindowButtonMotionFcn',...
                    animate_id(i));
            end
            updateView(getPosition());
        end
    end % newFigureMode
 
    %-----------------------------
	function animateLine(varargin)
        		
		[x_init,y_init] = getCurrentPoint_sv(h_axes);
        animate_pos = [getPosition(); x_init, y_init];
		updateView(animate_pos);
		
	end % animateLine
 
    %-------------------------------------
	function completed = placePolygon(x,y)
      	
	    is_double_click = strcmp(get(h_fig,'SelectionType'),'open');
	    is_right_click  = strcmp(get(h_fig,'SelectionType'),'alt');
        is_left_click = strcmp(get(h_fig, 'SelectionType'), 'normal');
        
        if ~is_left_click && (getNumVert()==0)
            completed = false;
            return
        end
	    
	    h_hit_test = hittest(h_fig);
        
        % Get hggroup that contains impoint HG group graphics objects so
        % that you can compare the output of hittest with the graphics of
        % the first vertex.       
        clicked_on_first_vertex = ...
                    ~isempty(h_vertices) &&...
                    h_hit_test == getVertexHGGroup(h_vertices{1});
	    
        completed = is_double_click || (is_closed && clicked_on_first_vertex);
	    
        % Distinction between right click and other completion gestures is
        % that right click placement ends on buttonUp.
        if completed || is_right_click
            setVertexPointerBehavior();
        else
            addVertex([x,y],getNumVert()+1);

            % Provide circle affordance to first vertex to communicate that polygon can
            % be closed by clicking on first vertex.
            if ( is_closed && (getNumVert() == 1) )
                setVertexPointerBehavior();
            end

        end
         
    end %placePolygon
    
    %-------------------------------------
    function completed = buttonUpPlacement
 
        completed  = strcmp(get(h_fig,'SelectionType'),'alt') &&...
                     getNumVert() > 0;
        
    end
  
    %--------------------------------
	function setVertexPointerBehavior

		for i = 1:getNumVert()
            
            iptSetPointerBehavior(h_vertices{i},...
                                @(h_fig,loc) set(h_fig,'Pointer','circle'));
                                
		end

	end %setVertexPointerBehavior

    %-----------------------------
    function num_vert = getNumVert
       
        num_vert = size(getPosition(),1);
        
    end
    
    %-------------------------------------
    function h_group = getVertexHGGroup(p)
       
        h_group = findobj(p,'type','hggroup');
        
    end

    %----------------------------------
    function idx = getActiveVertexIndex
       
        getActiveVertexIdx = @(p) isequal(getVertexHGGroup(p),h_active_vertex);
        idx = cellfun(getActiveVertexIdx,h_vertices);
        
    end
    
    %----------------------------------
    function updateVertexPositions(pos)
        % This function is called whenever the position of the polygon
        % changes. This function manages each impoint vertex instance to
        % keep each vertex in the appropriate position. If a user calls
        % setPosition with a different number of vertices than are
        % currently in the polygon, we delete all vertices and create the
        % require number of vertices from scratch.
        
        num_vert_drawn = length(h_vertices);
        if num_vert_drawn ~= getNumVert()
        
            for i = 1:num_vert_drawn
                h_vertices{i}.delete();
            end
            createVertices();
            setVertexContextMenu(cmenu_vertices);
            setContextMenu(cmenu_poly);
        else
                    
            for i = 1:getNumVert()
                h_vertices{i}.setPosition(pos(i,:));
            end
        end
               
    end %setPosition
    

    %--------------------------
    function vertexDragged(pos)
        
        candidate_position = getPosition();
        candidate_position(getActiveVertexIndex(),:) = pos;
        
        setConstrainedPosition(candidate_position);
                  
    end %vertexDragged
    
    %----------------------------------
    function vertexButtonDown(h_vertex) 
    
        h_active_vertex = h_vertex;
        
    end %vertexButtonDown
	      
    %----------------------
    function createVertices
    
        % If the number of vertices being drawn is being adjusted via a
        % call to setPosition, re-initialize h_vertices
        h_vertices = {};
        
        pos = getPosition();
        for i = 1:getNumVert()
            h_vertices{i} =  iptui.impolyVertex(h_group,pos(i,1),pos(i,2));
            
            % This is necessary to ensure that vertices are drawn with the
            % right color when setPosition alters the number of vertices
            % via updateVertexPositions
            h_vertices{i}.setColor(draw_api.getColor())
            
            % This pattern is done twice, however performance is better inline
            % than as a separate subfunction.
            addlistener(h_vertices{i}, 'ImpointButtonDown', ...
                @(vert,data) vertexButtonDown(getVertexHGGroup(vert)));
            
            addlistener(h_vertices{i}, 'ImpointDragged', ...
                @(vert,data) vertexDragged(vert.getPosition()));
              
        end
        setVertexPointerBehavior();
       	  
    end %createVertices
    
    %--------------------------
    function addVertex(pos,idx)
    % addVertex adds the vertex position pos to index idx of the resized (N+1)
    % by 2 position matrix.
        
		position = getPosition();
        num_vert = getNumVert() + 1;
              
        position_new = zeros(num_vert,2);
        h_vertices_new = cell(1,num_vert);
        
        position_new(idx,:) = pos;
        h_vertices_new{idx} = iptui.impolyVertex(h_group,pos(1),pos(2));
        
        addlistener(h_vertices_new{idx}, 'ImpointButtonDown', ...
            @(vert,data) vertexButtonDown(getVertexHGGroup(vert)));
        
        addlistener(h_vertices_new{idx}, 'ImpointDragged', ...
            @(vert,data) vertexDragged(vert.getPosition()));
                
        if num_vert > 1
      	  
      	  left_ind = 1:idx-1;
      	  right_ind = idx+1:num_vert;
      	  
      	  position_new(left_ind,:) = position(left_ind,:);
            h_vertices_new(left_ind) = h_vertices(left_ind);
      	  
      	  position_new(right_ind,:) = position(right_ind-1,:);
      	  h_vertices_new(right_ind) = h_vertices(right_ind-1);
      	  
        end	 
        
        h_vertices = h_vertices_new;
        
		setPosition(position_new);
       
    end %addVertex
    
    %----------------------------------------------
    function vertex_cmenu = createVertexContextMenu_sv
    % createVertexContextMenu creates a single context menu at the figure level
    % that is shared by all of the impoint instances used to define
    % vertices.  
        
        vertex_cmenu = createROIContextMenu_sv(h_fig,getPosition,@setColor);
        uimenu(vertex_cmenu,...
            'Label', getString(message('images:roiContextMenuUIString:deleteVertexContextMenuLabel')),...
            'Tag','delete vertex cmenu item',...
            'Callback',@deleteVertex);
        
        %------------------------------
        function deleteVertex(varargin)

            %Each vertex has a buttonDown callback wired to it which caches the last
            %vertex that was clicked on. The last vertex that received
            %buttonDown is the vertex which posted the delete context menu
            %option.
            idx = getActiveVertexIndex();
            vertex_being_deleted = h_vertices{idx};
            
            position = getPosition();

            h_vertices = h_vertices(~idx);
            position_new = position(~idx,:);

            vertex_being_deleted.delete();

            if ~isempty(position_new)
                setPosition(position_new);
            else
                % If the last vertex has been deleted, the entire polygon
                % should be destroyed.
                deletePolygon();

            end

            % Refresh pointer so that vertex affordance isn't showing if
            % you are no longer over a vertex
            iptPointerManager(h_fig,'Enable');

        end %deleteVertex

    end %createVertexContextMenu
    
end %impoly
