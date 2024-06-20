-- Define the FileSystem as a table with functions
FileSystem = {}

-- Constructor for FileSystem
function FileSystem.new(disk)
    local fs = {
        disk = disk,
        fsTree = disk:ReadEntireDisk() or {["/"] = {type = "directory", contents = {}}}
    }
    
    -- Helper function to verify the integrity of the file system
    function fs:verifyIntegrity(node)
        if type(node) ~= "table" then
            return false
        end
        if node.type == "directory" then
            if type(node.contents) ~= "table" then
                return false
            end
            for _, child in pairs(node.contents) do
                if not self:verifyIntegrity(child) then
                    return false
                end
            end
        elseif node.type == "file" then
            if type(node.content) ~= "string" then
                return false
            end
        else
            return false
        end
        return true
    end

    -- Verify the integrity of the root directory
    if not fs:verifyIntegrity(fs.fsTree["/"]) then
        disk:ClearDisk()
        fs.fsTree = {["/"] = {type = "directory", contents = {}}}
    end

    -- Helper function to navigate to the correct node
    function fs:navigate(path)
        local node = self.fsTree["/"]
        for part in path:gmatch("[^/]+") do
            if node.type == "directory" then
                node = node.contents[part]
                if not node then
                    return nil
                end
            else
                return nil
            end
        end
        return node
    end

    -- Create a new directory
    function fs.mkdir(path)
        local node = fs.fsTree["/"]
        for part in path:gmatch("[^/]+") do
            if not node.contents[part] then
                node.contents[part] = {
                    name = part,
                    type = "directory",
                    contents = {}
                }
            end
            node = node.contents[part]
        end
        fs.disk:Write("/", fs.fsTree)
    end

    -- Create a new file
    function fs.touch(path)
        local dirPath, fileName = path:match("(.+)/([^/]+)$")
        if not dirPath then dirPath = "/" end
        local dir = fs:navigate(dirPath)
        if dir and dir.type == "directory" then
            dir.contents[fileName] = {
                name = fileName,
                type = "file",
                content = ""
            }
        end
        fs.disk:Write("/", fs.fsTree)
    end

    -- Write to a file
    function fs.write(path, content)
        local file = fs:navigate(path)
        if file and file.type == "file" then
            file.content = content
            fs.disk:Write("/", fs.fsTree)
        end
    end

    -- Read from a file
    function fs.read(path)
        local file = fs:navigate(path)
        if file and file.type == "file" then
            return file.content
        end
        return nil
    end

    -- List directory contents
    function fs.ls(path)
        local dir = fs:navigate(path)
        local contents = {}
        if dir and dir.type == "directory" then
            for name, node in pairs(dir.contents) do
                table.insert(contents, name .. " " .. node.type)
            end
        end
        return contents
    end

    return fs
end

local disk = GetPartFromPort(1, "Disk")
disk:Write("result", FileSystem)
