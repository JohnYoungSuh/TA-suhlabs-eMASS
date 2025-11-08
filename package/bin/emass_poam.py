"""
eMASS POA&M Modular Input
Collects POA&M (Plan of Action & Milestones) data from eMASS API
"""

import import_declare_test  # noqa: F401

import json
import sys
import time
from typing import Dict, Any

import requests
from splunklib import modularinput as smi
from solnlib import conf_manager
from solnlib import log
from solnlib.modular_input import checkpointer


# Set up logging
logger = log.Logs().get_logger("ta_securepro_emass_emass_poam")


class EMASS_POAM(smi.Script):
    """
    Modular Input for collecting eMASS POA&M data
    """

    def __init__(self):
        super(EMASS_POAM, self).__init__()

    def get_scheme(self):
        """
        Define the input scheme for Splunk
        """
        scheme = smi.Scheme('emass_poam')
        scheme.description = 'eMASS POA&M Collection'
        scheme.use_external_validation = True
        scheme.streaming_mode_xml = True
        scheme.use_single_instance = False

        # Only define custom arguments here
        # Splunk provides these automatically: name, interval, index, sourcetype, etc.
        scheme.add_argument(
            smi.Argument(
                'account',
                title='eMASS Account',
                description='eMASS account to use for data collection',
                required_on_create=True,
            )
        )
        return scheme

    def validate_input(self, definition: smi.ValidationDefinition):
        """
        Validate the input configuration
        """
        return

    def stream_events(self, inputs: smi.InputDefinition, ew: smi.EventWriter):
        """
        Stream events from eMASS API to Splunk
        """
        # Get session key for accessing Splunk configs
        session_key = self._input_definition.metadata.get("session_key")

        for input_name, input_item in inputs.inputs.items():
            try:
                logger.info(f"Starting collection for input: {input_name}")

                # Extract configuration
                account_name = input_item.get("account")
                interval = int(input_item.get("interval", 300))
                index = input_item.get("index", "default")

                # Get account configuration
                account_config = self._get_account_config(session_key, account_name)
                if not account_config:
                    logger.error(f"Account '{account_name}' not found")
                    continue

                # Extract account details
                base_url = account_config.get("base_url", "").rstrip("/")
                system_id = account_config.get("system_id")
                api_key = account_config.get("api_key")

                # Use account's default index if specified, otherwise use input's index
                account_index = account_config.get("index")
                if account_index:
                    index = account_index
                    logger.info(f"Using default index from account: {index}")

                if not all([base_url, system_id, api_key]):
                    logger.error(f"Account '{account_name}' is missing required fields")
                    continue

                # Construct API endpoint URL
                api_url = f"{base_url}/api/systems/{system_id}/poams"
                logger.info(f"Constructed API URL: {api_url}")

                # Collect data from API
                poams = self._collect_poams(api_url, api_key)

                if poams:
                    logger.info(f"Collected {len(poams)} POA&Ms from {api_url}")

                    # Write events to Splunk
                    for poam in poams:
                        event = smi.Event(
                            data=json.dumps(poam),
                            sourcetype='emass:poam',
                            index=index,
                            source=api_url,
                        )
                        ew.write_event(event)
                else:
                    logger.info(f"No POA&Ms found at {api_url}")

            except Exception as e:
                logger.error(f"Error processing input {input_name}: {str(e)}")
                continue

    def _get_account_config(self, session_key: str, account_name: str) -> Dict[str, Any]:
        """
        Retrieve account configuration from Splunk

        Args:
            session_key: Splunk session key
            account_name: Name of the account to retrieve

        Returns:
            Dictionary containing account configuration
        """
        try:
            cfm = conf_manager.ConfManager(
                session_key,
                "TA-securepro-eMASS",
                realm="__REST_CREDENTIAL__#TA-securepro-eMASS#configs/conf-ta_securepro_emass_account"
            )

            # Get the account configuration
            account_conf = cfm.get_conf("ta_securepro_emass_account")
            account_stanza = account_conf.get(account_name)

            if account_stanza:
                return {
                    "base_url": account_stanza.get("base_url"),
                    "system_id": account_stanza.get("system_id"),
                    "api_key": account_stanza.get("api_key"),
                    "index": account_stanza.get("index"),
                }

            return None

        except Exception as e:
            logger.error(f"Error retrieving account config for '{account_name}': {str(e)}")
            return None

    def _collect_poams(self, api_url: str, api_key: str) -> list:
        """
        Collect POA&Ms from eMASS API

        Args:
            api_url: Full API endpoint URL
            api_key: API key for authentication

        Returns:
            List of POA&M dictionaries
        """
        try:
            headers = {
                "api-key": api_key,
                "Accept": "application/json"
            }

            logger.debug(f"Making request to: {api_url}")
            response = requests.get(api_url, headers=headers, timeout=30)

            if response.status_code == 200:
                data = response.json()

                # Handle different response formats
                if isinstance(data, list):
                    return data
                elif isinstance(data, dict):
                    # Check for common pagination/wrapper keys
                    if "poams" in data:
                        return data["poams"]
                    elif "data" in data:
                        return data["data"]
                    elif "items" in data:
                        return data["items"]
                    else:
                        # Return as single-item list if it's an object
                        return [data]
                return []
            else:
                logger.error(f"API request failed with status {response.status_code}: {response.text}")
                return []

        except requests.exceptions.Timeout:
            logger.error(f"Request timeout for {api_url}")
            return []
        except requests.exceptions.RequestException as e:
            logger.error(f"Request error for {api_url}: {str(e)}")
            return []
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error for {api_url}: {str(e)}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error collecting POA&Ms: {str(e)}")
            return []


if __name__ == '__main__':
    exit_code = EMASS_POAM().run(sys.argv)
    sys.exit(exit_code)
