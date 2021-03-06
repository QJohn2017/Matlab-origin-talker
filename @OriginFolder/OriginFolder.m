classdef OriginFolder < OriginObject
    %ORIGINFOLDER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        parent
        isRoot
    end
    
    methods (Access = public, Static = true)
        
    end
    
    methods (Access = public)
        function obj = OriginFolder(originFolderObj,parent,isRoot)
            if nargin == 0
                % OriginFolder()
                obj.name = [];
                obj.parent = [];
                obj.isRoot = [];
                obj.originObj = [];
            elseif nargin == 1
                % OriginFolder(originFolderObj)
                obj.name = originFolderObj.get('Name');
                obj.originObj = originFolderObj;
                obj.parent = obj.getParent();
            elseif nargin == 3
                % OriginFolder(originFolderObj,parent,isRoot)
                obj.name = originFolderObj.get('Name');
                obj.parent = parent;
                obj.isRoot = isRoot;
                obj.originObj = originFolderObj;
            end
        end
        
        function delete(obj)
%             % delete this folder
%             % if originFolderObj is empty there is no need to call 'destroy'
%             if ~isempty(obj.originObj)
%                 obj.originObj.invoke('Destroy');
%             end
%             
%             % call super class delete method
%             delete@OriginObject(obj);
        end
        
        function [subFolders,Pages] =  ls(obj)
            originFoldersObj = obj.originObj.invoke('Folders');
            count = originFoldersObj.get('count');
            if count >0
                % subFolders(1,count) = OriginFolder();
                Pages = zeros(1,count);
                for ii = 1:count
                    % get original origin Folder object
                    originFolderObj = invoke(originFoldersObj,'item',uint8(ii-1));
                    % save to OriginFolder Object
                    subFolders(ii) = OriginFolder(originFolderObj,obj,false); %#ok<AGROW>
                end
            else
                % there is not Null in Matlab
                subFolders = [];
                Pages = [];
            end
        end
        
        function newFolder = mkdir(obj,newDirName,varargin)
            % Create a new dictory in the folder specified by obj, return
            % the newly created dictory as an OriginFolder object
            
            % Check if folder exist. Because adding a folder with the same
            % name as an existing folder will delete everything it contains
            % and Origin gives you no warning.
            S = regexp(newDirName, filesep, 'split');
            if ~isempty(S)
                newFolder = obj;
                for ii = 1:length(S)
                    if ~isempty(S{ii})
                        try
                            % check if can open folder if exists
                            newFolder = newFolder.cd(newDirName);
                        catch e
                            if strcmp(e.identifier,'OriginFolder:pathNotFound')
                                % folder does not exist (or TODO path is invalid)
                                originFoldersObj = newFolder.originObj.invoke('Folders');
                                % Todo: some reg here
                                originFoldersObj.invoke('Add',S{ii});
                                % get the real origin folder
                                originFolderObj = originFoldersObj.invoke('FolderFromPath',S{ii});
                                % generate the new folder object and return
                                newFolder = OriginFolder(originFolderObj,obj,false);
                            else
                                newFolder = [];
                            end
                        end
                    end
                end
            else
                newFolder = [];
            end
            
            
        end
        
        function f = cd(obj,path)
            % Return a new folder using obj as base and path as a relative
            % path
            % This does nor change the active folder of the Origin session
            % assume a path like this '\new folder\new folder 2\new folder3\'
            % or 'new folder\new folder 2\new folder3'
            f = obj;
            S = regexp(path, filesep, 'split');
            for ii = 1:length(S)
                if ~isempty(S{ii})
                    temp = f.findSubFolderbyName(char(S{ii}));
                    if ~isempty(temp)
                        f = temp;
                    else
                        error('OriginFolder:pathNotFound','path not found')
                    end
                end
            end
        end
        
        function f = findSubFolderbyName(obj,name)
            [subFolders,~] =  ls(obj);
            for ii = 1:length(subFolders)
                if strcmp(subFolders(ii).name,name)
                    f = subFolders(ii);
                end
            end
            if ~exist('f','var')
                f = [];
            end
        end
        
        function p = toPath(obj)
            p = obj.originObj.invoke('path');
        end
        
        function f = getParent(obj)
            parentObj = obj.originObj.invoke('Parent');
            % find out whether parentObj has parent
            % rootfolder's parent is Application
            % Application has no parents
            try 
                parentObj.invoke('Parent');
                parentObjIsApplication = false;
            catch
                parentObjIsApplication = true;
            end
            if parentObjIsApplication
                obj.isRoot = true;
                f = [];
            else
                obj.isRoot = false;
                f = OriginFolder(parentObj);
            end
        end
        
    end
    
end

