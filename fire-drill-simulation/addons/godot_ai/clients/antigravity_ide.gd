@tool
extends McpClient


func _init() -> void:
	id = "antigravity_ide"
	display_name = "Antigravity IDE"
	config_type = "json"
	doc_url = "https://www.antigravity.dev/"
	path_template = {
		"unix": "~/.gemini/config/mcp_config.json",
		"windows": "$USERPROFILE/.gemini/config/mcp_config.json",
	}
	server_key_path = PackedStringArray(["mcpServers"])
	entry_uvx_bridge = McpClient.UvxBridge.FLAT
	detect_paths = PackedStringArray(path_template.values())
