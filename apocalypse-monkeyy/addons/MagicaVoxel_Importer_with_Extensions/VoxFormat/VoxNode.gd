enum NodeType {
	UNKNOWN,
	TRANSFORM,
	GROUP,
	SHAPE,
}

var id: int;
var attributes = {};
var node_type: int = NodeType.UNKNOWN;
var layerId := -1;
var child_nodes = [];
var models = {};
var transforms = { 0: { "position": Vector3(), "rotation": Basis() } };

func _init(node_id, node_attributes, imported_node_type = NodeType.UNKNOWN):
	id = node_id;
	attributes = node_attributes;
	node_type = imported_node_type;
