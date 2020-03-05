import re
import os

def trimNonAlphaNumsSides(strToTrim):
    #Trims the non-alphanumeric characters on the sides of the mesh
    ret = [0,len(strToTrim)]
    forbiddenRegex = r'[\s]'
    
    for i in range(0, len(strToTrim)):
        if not re.match(forbiddenRegex, strToTrim[i]):
            ret[0] = i
            break

    for i in range(len(strToTrim)-1, -1, -1):
        if not re.match(forbiddenRegex, strToTrim[i]):
            ret[1] = i+1
            break

    return strToTrim[ret[0] : ret[1]]
    
def extractLinearData(dataLine):
    #From a string of form [name a=b c=d] returns {a : b, c : d} etc.
    varsList = list(re.finditer(r'\s(([^=]*)=)', dataLine))
    vars_ = {}
    
    for i in range(0, len(varsList) - 1):
        vars_[varsList[i].group(2)] = dataLine[varsList[i].span()[1] : varsList[i+1].span()[0]]
    
    vars_[varsList[-1].group(2)] = dataLine[varsList[-1].span()[1] : dataLine.rfind(']')]
    
    for var in vars_:
        vars_[var] = trimNonAlphaNumsSides(vars_[var])
    
    return vars_

def findObjectsData(buildingCode, objType):
    objsList = list(re.finditer(r'\[{}[^]]*\]'.format(objType) , buildingCode))
    if len(objsList) == 0:
        return [[],[]]
    else:
        objsCode = []
        for i in range(0, len(objsList) - 1):
            objsCode.append(buildingCode[objsList[i].span()[1] : objsList[i+1].span()[0]])
        
        lastObjEndSpan = objsList[len(objsList) -1].span()[1]
        match = re.search(r'\[\w* \w*=[^]]*\]', buildingCode[lastObjEndSpan : len(buildingCode) - 1])

        if match:
            objsCode.append(buildingCode[lastObjEndSpan : lastObjEndSpan + match.span()[0]])
        else:
            objsCode.append(buildingCode[lastObjEndSpan : lastObjEndSpan + len(buildingCode) - 1])
            
        #And then read that code to extract the infos
        objsVars = []
        for i in range(0, len(objsCode)):
            objCode = objsCode[i]
            objsValues = {}
            objVars = list(re.finditer(r'\n([^=]*) =', objCode))
            for i in range(0, len(objVars)):
                rightExtreme = 0
                if i < len(objVars) - 1:
                    rightExtreme = objVars[i+1].span()[0]	
                else:
                    rightExtreme = len(objCode)
                objVar = trimNonAlphaNumsSides(objVars[i].group(1))
                objVarValue = trimNonAlphaNumsSides(objCode[objVars[i].span()[1]+1: rightExtreme])
                if objVar != '':
                    objsValues[objVar] = objVarValue
                    
            objsVars.append(objsValues)
            
        #We find the objs params (the infos in the header)
        objsParams = []
        for obj in objsList:
            dataDict = extractLinearData(obj.group(0))
            objsParams.append(dataDict)
                    
        return [objsParams, objsVars]

class GodotObject:
    def __init__(self, type, params, vars):
        self.params = params
        self.vars = vars
        self.type = type

    def __str__(self):
        ret = '[{}'.format(self.type)
        
        for param in self.params:
            ret += ' ' + param + '=' + self.params[param]

        ret += ']\n'

        for var in self.vars:
            ret += var + ' = ' + str(self.vars[var]) + '\n'

        return ret

class Node(GodotObject):
    def __init__(self, params, vars):
        GodotObject.__init__(self, 'node', params, vars)

class GodotResource(GodotObject):
    def __init__(self, type, params, vars, refsCount):
        GodotObject.__init__(self, type, params, vars)
        self.refsCount = refsCount

class GodotFile:
    def addNode(self, params, vars):
        self.nodes.append(Node(params, vars))

    def addExtRes(self, params):
        self.externalResources.append(GodotResource('ext_resource', params, {}, 0))

    def addSubRes(self, params, vars):
        self.subResources.append(GodotResource('sub_resource', params, vars, 0))

    def getNodeAbsPath(self, node):
        if node.params['parent'] != '.':
            return os.path.join(node.params['parent'], node.params['name'])
        else:
            return node.params['name']

    def removeNodes(self, nodesToRemove):         
        for node in nodesToRemove:
            nodeAbsPath = self.getNodeAbsPath(node)
            
            if 'parent' in node.params:
                if node.params['parent'] != '.':
                    pathToRemove = os.path.join(node.params['parent'], node.params['name'])
                    for path in self.editablePaths:
                        if path.params['path'] == pathToRemove:
                            self.editablePaths.remove(path)
                            break
                    for connection in self.connections.copy():
                        for target in ['to','from']:
                            match = re.match(nodeAbsPath, connection.params[target])
                            if match != None:
                                if match.span()[0] == 0 and (match.span()[1] == len(connection.params[target]) or connection.params[target][min(len(connection.params[target]) - 1, match.span()[1])] == '/'):
                                    self.connections.remove(connection)
                                    break
            #We then remove those nodes
            self.nodes.remove(node)
            
        #We finally remove the now-unused resources
        self.countResourcesRefs()
        for res in self.externalResources.copy():
            if res.refsCount == 0:
                self.externalResources.remove(res)
        for res in self.subResources.copy():
            if res.refsCount == 0:
                self.subResources.remove(res)

    def findExtResOfParams(self, params):
        #Returns the external resources matching params' requirement
        #params is a dict
        ret = []

        for extRes in self.externalResources:
            matchingValues = True
            for param in params:
                if param in extRes.params:
                    if params[param] != extRes.params[param]:
                        matchingValues = False
                        break
                else:
                    matchingValues = False
                    break
            
            if matchingValues:
                ret.append(extRes)
        
        return ret

    def __init__(self, filepath):
        godotFile = open(filepath, 'r')
        fileCode = godotFile.read()
        godotFile.close()

        #Finds all parts of code describing resources (and extract data)
        self.externalResources = []
        for resData in findObjectsData(fileCode, 'ext_resource')[0]:
            self.addExtRes(resData)

        subData = findObjectsData(fileCode, 'sub_resource')
        self.subResources = []
        for i in range(0, len(subData[0])):
            self.addSubRes(subData[0][i], subData[1][i])
            
        #Finds all parts of code describing nodes
        self.nodes = []
        nodesData = findObjectsData(fileCode, 'node')
        for i in range(0,len(nodesData[0])):
            self.addNode(nodesData[0][i], nodesData[1][i])

        self.countResourcesRefs()

        #Find all the connections
        self.connections = []
        for resData in findObjectsData(fileCode, 'connection')[0]:
            self.connections.append(GodotResource('connection', resData, {}, 0))

        #We finally find the editable resources : the apartments themselves
        self.editablePaths = []
        for resData in findObjectsData(fileCode, 'editable')[0]:
            self.editablePaths.append(GodotResource('editable', resData, {}, 0))
    
    def writeToFile(self, filepath):
        fileCode = ''

        fileCode += '[gd_scene load_steps={} format=2]\n'.format(1+len(self.externalResources)+len(self.subResources))
        fileCode += '\n'

        for extRes in self.externalResources:
            fileCode += extRes.__str__()
        fileCode += '\n'

        for subRes in self.subResources:
            fileCode += subRes.__str__() + '\n'
        fileCode += '\n'

        for node in self.nodes:
            fileCode += node.__str__() + '\n'
        
        for conn in self.connections:
            fileCode += conn.__str__()
        fileCode += '\n'

        for editPath in self.editablePaths:
            fileCode += editPath.__str__() + '\n'
        
        godotFile = open(filepath, 'w+')
        godotFile.write(fileCode)
        godotFile.close()
        
    def _reindexDictRes(self, dict_, originalId, newId, resType):
        for var in dict_:
            match = re.match(r'{}\( {} \)'.format(resType, originalId), dict_[var])
            if match:
                dict_[var] = '{}( {} )'.format(resType, newId)

    def reindexResources(self):
        #Reorders the indexes of resources, to be ordered from 1 to n
        for i in range(0, len(self.externalResources)):
            originalId = self.externalResources[i].params['id']
            newId = str(i+1)
            if originalId != newId:
                for node in self.nodes:
                    self._reindexDictRes(node.params, originalId, newId, 'ExtResource')
                    self._reindexDictRes(node.vars, originalId, newId, 'ExtResource')

            self.externalResources[i].params['id'] = str(i+1)

    def _addDictResRefs(self, dict_):
        for var in dict_:
            matchExt = re.match(r'ExtResource\( (\d*) \)', dict_[var])
            if matchExt:
                self.externalResources[int(matchExt.group(1))-1].refsCount += 1
            else:
                matchSub = re.match(r'SubResource\( (\d*) \)', dict_[var])
                if matchSub:
                    self.subResources[int(matchSub.group(1))-1].refsCount += 1

    def countResourcesRefs(self):
        #We zero all the refs counts
        self.reindexResources()
        for i in range(0, len(self.externalResources)):
            self.externalResources[i].refsCount = 0
        
        for i in range(0, len(self.subResources)):
            self.subResources[i].refsCount = 0
        
        for node in self.nodes:
            self._addDictResRefs(node.params)
            self._addDictResRefs(node.vars)
