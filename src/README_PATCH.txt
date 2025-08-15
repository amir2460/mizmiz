
Patch notes (Aug 15, 2025):
- Added compatibility helpers to support latest 3x-ui (Sanaei) /panel/api routes while keeping legacy endpoints.
- Introduced xui_login, xui_supports_new_api, xui_update_inbound_url, xui_delete_client, xui_add_client.
- Rewired update-inbound URL builders to use helper (config.php).
- No breaking changes for existing flows; legacy /xui/inbound/update continues to work if new API is absent.
- Ubuntu 22+ compatibility: relies on PHP 8.1+ and cURL; SSL verification is disabled for panel self-signed certs by default.
