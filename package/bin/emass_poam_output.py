"""
eMASS POA&M Output Modular Script
Sends POAM updates to eMASS API via POST/PUT operations
"""

import import_declare_test  # noqa: F401

import json
import sys
import time
from typing import Dict, Any, Optional

import requests
from splunklib import modularinput as smi
from solnlib import conf_manager
from solnlib import log
from solnlib.modular_input import checkpointer


# Set up logging
logger = log.Logs().get_logger("ta_suhlabs_emass_emass_poam_output")


class EMASS_POAM_Output(smi.Script):
    """
    Modular Output for sending POAM updates to eMASS
    """

    def __init__(self):
        super(EMASS_POAM_Output, self).__init__()

    def get_scheme(self):
        """
        Define the output scheme for Splunk
        """
        scheme = smi.Scheme('emass_poam_output')
        scheme.description = 'eMASS POA&M Output - Send updates to eMASS'
        scheme.use_external_validation = True
        scheme.streaming_mode_xml = True
        scheme.use_single_instance = False

        scheme.add_argument(
            smi.Argument(
                'name',
                title='Output Name',
                description='Unique name for this output configuration',
                required_on_create=True,
            )
        )
        scheme.add_argument(
            smi.Argument(
                'account',
                title='eMASS Account',
                description='eMASS account to use for sending updates',
                required_on_create=True,
            )
        )
        scheme.add_argument(
            smi.Argument(
                'http_method',
                title='HTTP Method',
                description='HTTP method for POAM updates (POST or PUT)',
                required_on_create=True,
            )
        )
        scheme.add_argument(
            smi.Argument(
                'source_index',
                title='Source Index',
                description='Splunk index to monitor for POAM changes',
                required_on_create=True,
            )
        )
        return scheme

    def validate_input(self, definition: smi.ValidationDefinition):
        """
        Validate the output configuration
        """
        http_method = definition.parameters.get("http_method", "").upper()
        if http_method not in ["POST", "PUT"]:
            raise ValueError(f"Invalid HTTP method: {http_method}. Must be POST or PUT")
        return

    def stream_events(self, inputs: smi.InputDefinition, ew: smi.EventWriter):
        """
        Process and send POAM updates to eMASS API
        
        Note: This is a modular output, so it monitors Splunk for events
        and sends them to eMASS when triggered.
        """
        # Get session key for accessing Splunk configs
        session_key = self._input_definition.metadata.get("session_key")

        # Initialize checkpointer for tracking sent POAMs
        ckpt = checkpointer.KVStoreCheckpointer(
            "ta_suhlabs_emass_emass_poam_output",
            session_key,
            "TA-suhlabs-eMASS"
        )

        for input_name, input_item in inputs.inputs.items():
            try:
                logger.info(f"Starting output processing for: {input_name}")

                # Extract configuration
                account_name = input_item.get("account")
                http_method = input_item.get("http_method", "POST").upper()
                source_index = input_item.get("source_index", "main")

                # Get account configuration
                account_config = self._get_account_config(session_key, account_name)
                if not account_config:
                    logger.error(f"Account '{account_name}' not found")
                    continue

                # Extract account details
                base_url = account_config.get("base_url", "").rstrip("/")
                system_id = account_config.get("system_id")
                api_key = account_config.get("api_key")
                user_uid = account_config.get("user_uid")

                if not all([base_url, system_id, api_key]):
                    logger.error(f"Account '{account_name}' is missing required fields")
                    continue

                # Construct API endpoint URL
                api_url = f"{base_url}/api/systems/{system_id}/poams"
                logger.info(f"Output endpoint: {api_url} (Method: {http_method})")

                # In a real implementation, you would:
                # 1. Query Splunk for events from source_index that need to be sent
                # 2. Process each event and send to eMASS
                # 3. Update checkpoint to track what's been sent
                
                # For now, log that the output is configured and ready
                logger.info(f"Output '{input_name}' is configured and monitoring index '{source_index}'")
                logger.info(f"Will use {http_method} method to send POAMs to {api_url}")

            except Exception as e:
                logger.error(f"Error processing output {input_name}: {str(e)}")
                continue

    def _get_account_config(self, session_key: str, account_name: str) -> Optional[Dict[str, Any]]:
        """
        Retrieve account configuration from Splunk

        Args:
            session_key: Splunk session key
            account_name: Name of the account to retrieve

        Returns:
            Dictionary containing account configuration or None
        """
        try:
            cfm = conf_manager.ConfManager(
                session_key,
                "TA-suhlabs-eMASS",
                realm="__REST_CREDENTIAL__#TA-suhlabs-eMASS#configs/conf-ta_suhlabs_emass_account"
            )

            # Get the account configuration
            account_conf = cfm.get_conf("ta_suhlabs_emass_account")
            account_stanza = account_conf.get(account_name)

            if account_stanza:
                return {
                    "base_url": account_stanza.get("base_url"),
                    "system_id": account_stanza.get("system_id"),
                    "api_key": account_stanza.get("api_key"),
                    "user_uid": account_stanza.get("user_uid"),
                }

            return None

        except Exception as e:
            logger.error(f"Error retrieving account config for '{account_name}': {str(e)}")
            return None

    def _send_poam_update(
        self, 
        api_url: str, 
        api_key: str, 
        poam_data: Dict[str, Any],
        http_method: str = "POST",
        user_uid: Optional[str] = None,
        poam_id: Optional[str] = None
    ) -> bool:
        """
        Send POAM update to eMASS API

        Args:
            api_url: Base API endpoint URL
            api_key: API key for authentication
            poam_data: POAM data to send
            http_method: HTTP method (POST or PUT)
            user_uid: User UID for authentication (optional)
            poam_id: POAM ID for PUT requests (required for PUT)

        Returns:
            True if successful, False otherwise
        """
        try:
            headers = {
                "api-key": api_key,
                "Content-Type": "application/json",
                "Accept": "application/json"
            }

            if user_uid:
                headers["user-uid"] = user_uid

            # Construct full URL
            if http_method == "PUT" and poam_id:
                url = f"{api_url}/{poam_id}"
            else:
                url = api_url

            logger.debug(f"Sending {http_method} request to: {url}")

            # Send request
            if http_method == "POST":
                response = requests.post(url, headers=headers, json=poam_data, timeout=30)
            elif http_method == "PUT":
                response = requests.put(url, headers=headers, json=poam_data, timeout=30)
            else:
                logger.error(f"Unsupported HTTP method: {http_method}")
                return False

            if response.status_code in [200, 201, 204]:
                logger.info(f"{http_method} request successful: {response.status_code}")
                return True
            else:
                logger.error(f"{http_method} request failed with status {response.status_code}: {response.text}")
                return False

        except requests.exceptions.Timeout:
            logger.error(f"Request timeout for {url}")
            return False
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error for {url}: {str(e)}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error sending POAM update: {str(e)}")
            return False


if __name__ == '__main__':
    exit_code = EMASS_POAM_Output().run(sys.argv)
    sys.exit(exit_code)
