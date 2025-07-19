#!/usr/bin/env python3
"""
GMX Layout Server Example

This is a reference implementation of a layout server for the GMX client framework.
The server manages layout definitions and sends them to connected GMX clients via
XML socket connections.

Features:
- Socket-based XML message handling
- Layout storage and management by LUID
- Client connection management
- Basic layout validation
- Example layout definitions

Usage:
    python layout_server.py [--host HOST] [--port PORT]

Dependencies:
    - Python 3.6+
    - xml.etree.ElementTree (built-in)
    - socket (built-in)
    - threading (built-in)
"""

import socket
import threading
import xml.etree.ElementTree as ET
import argparse
import logging
import time
from typing import Dict, List, Optional
import json


class LayoutServer:
    """
    GMX Layout Server implementation

    Manages layout definitions and serves them to GMX clients via XML socket connections.
    """

    def __init__(self, host: str = 'localhost', port: int = 12345):
        self.host = host
        self.port = port
        self.layouts: Dict[str, str] = {}
        self.clients: List[socket.socket] = []
        self.running = False
        self.server_socket: Optional[socket.socket] = None

        # Set up logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

        # Load default layouts
        self._load_default_layouts()

    def _load_default_layouts(self):
        """Load default layout definitions"""

        # Simple button layout
        simple_layout = '''
        <VBox luid="mainLuid" width="300" height="200" gap="20"
              horizontalAlign="center" verticalAlign="middle"
              backgroundColor="0xF0F0F0" paddingTop="20" paddingLeft="20" paddingRight="20" paddingBottom="20">
            <Label text="Welcome to GMX" fontSize="16" fontWeight="bold" color="0x333333"/>
            <Button label="Click Me!" width="120" height="40"
                   ruid="button_record" fid="click_action" fontSize="14"/>
            <Label text="Ready" ruid="button_record" fid="status_message"
                  fontSize="12" color="0x666666" textAlign="center"/>
        </VBox>
        '''

        # Basic form layout
        form_layout = '''
        <VBox luid="mainLuid" width="400" height="500" gap="10" paddingTop="20" paddingLeft="20" paddingRight="20">
            <Label text="User Registration Form" fontSize="18" fontWeight="bold" color="0x333333"/>
            <Spacer height="10"/>
            <VBox gap="8" width="100%">
                <HBox gap="10" verticalAlign="middle">
                    <Label text="Username:" width="100" textAlign="right"/>
                    <TextInput width="200" height="25" ruid="user_form_record" fid="username" maxChars="50"/>
                </HBox>
                <HBox gap="10" verticalAlign="middle">
                    <Label text="Email:" width="100" textAlign="right"/>
                    <TextInput width="200" height="25" ruid="user_form_record" fid="email" maxChars="100"/>
                </HBox>
                <HBox gap="10" verticalAlign="middle">
                    <Label text="Password:" width="100" textAlign="right"/>
                    <TextInput width="200" height="25" ruid="user_form_record" fid="password" displayAsPassword="true"/>
                </HBox>
            </VBox>
            <HBox gap="15" horizontalAlign="center">
                <Button label="Submit" width="80" height="30" ruid="user_form_record" fid="submit_action"/>
                <Button label="Cancel" width="80" height="30" ruid="user_form_record" fid="cancel_action"/>
            </HBox>
        </VBox>
        '''

        # Dashboard layout
        dashboard_layout = '''
        <HBox luid="mainLuid" width="1024" height="768" gap="5" paddingTop="10" paddingLeft="10" paddingRight="10">
            <VBox luid="sidebar_container" width="250" height="100%" gap="10" backgroundColor="0xF5F5F5">
                <VBox gap="5" width="100%" backgroundColor="0xFFFFFF" paddingTop="10" paddingBottom="10" paddingLeft="10" paddingRight="10">
                    <Label text="System Status" fontSize="14" fontWeight="bold"/>
                    <Label ruid="system_status" fid="status_text" fontSize="12"/>
                    <Label ruid="system_status" fid="uptime" fontSize="12" color="0x006600"/>
                </VBox>
                <VBox gap="8" width="100%">
                    <Label text="Navigation" fontSize="14" fontWeight="bold"/>
                    <Compass_X width="80" height="80" ruid="navigation_data" fid="magnetic_heading"/>
                    <TurnRateIndicator_X width="80" height="80" ruid="navigation_data" fid="turn_rate"/>
                </VBox>
            </VBox>
            <VBox luid="main_content" width="100%" height="100%" gap="10">
                <HBox height="40" width="100%" backgroundColor="0x333333" paddingLeft="15" paddingRight="15" verticalAlign="middle">
                    <Label text="Dashboard" fontSize="16" fontWeight="bold" color="0xFFFFFF"/>
                    <Spacer width="100%"/>
                    <Label ruid="system_status" fid="current_time" fontSize="12" color="0xCCCCCC"/>
                </HBox>
                <DataGrid width="100%" height="300" cuid="system_metrics" selectable="true">
                    <columns>
                        <DataGridColumn headerText="Metric" dataField="metric_name" width="120"/>
                        <DataGridColumn headerText="Value" dataField="current_value" width="100"/>
                        <DataGridColumn headerText="Status" dataField="status" width="80"/>
                    </columns>
                </DataGrid>
            </VBox>
        </HBox>
        '''

        # Store layouts with their LUIDs
        self.layouts['simple'] = simple_layout
        self.layouts['form'] = form_layout
        self.layouts['dashboard'] = dashboard_layout
        self.layouts['mainLuid'] = simple_layout  # Default layout

        self.logger.info(f"Loaded {len(self.layouts)} default layouts")

    def add_layout(self, luid: str, layout_xml: str) -> bool:
        """
        Add or update a layout definition

        Args:
            luid: Layout Unique ID
            layout_xml: XML layout definition

        Returns:
            True if layout was added successfully, False otherwise
        """
        try:
            # Validate XML
            ET.fromstring(layout_xml)
            self.layouts[luid] = layout_xml
            self.logger.info(f"Added layout for LUID: {luid}")
            return True
        except ET.ParseError as e:
            self.logger.error(f"Invalid XML for LUID {luid}: {e}")
            return False

    def get_layout(self, luid: str) -> Optional[str]:
        """Get layout definition by LUID"""
        return self.layouts.get(luid)

    def remove_layout(self, luid: str) -> bool:
        """Remove layout definition"""
        if luid in self.layouts:
            del self.layouts[luid]
            self.logger.info(f"Removed layout for LUID: {luid}")
            return True
        return False

    def list_layouts(self) -> List[str]:
        """Get list of available layout LUIDs"""
        return list(self.layouts.keys())

    def send_layout(self, client: socket.socket, luid: str) -> bool:
        """
        Send layout to specific client

        Args:
            client: Client socket
            luid: Layout Unique ID

        Returns:
            True if sent successfully, False otherwise
        """
        if luid not in self.layouts:
            self.logger.warning(f"Layout not found for LUID: {luid}")
            return False

        try:
            # Wrap layout in ISISLayout message
            layout_content = self.layouts[luid].strip()
            # Remove XML declaration if present
            if layout_content.startswith('<?xml'):
                layout_content = layout_content.split('?>', 1)[1].strip()

            message = f'<ISISLayout luid="{luid}">{layout_content}</ISISLayout>\0'
            client.send(message.encode('utf-8'))
            self.logger.info(f"Sent layout '{luid}' to client")
            return True
        except Exception as e:
            self.logger.error(f"Failed to send layout to client: {e}")
            return False

    def broadcast_layout(self, luid: str):
        """Broadcast layout to all connected clients"""
        if luid not in self.layouts:
            self.logger.warning(f"Cannot broadcast: Layout not found for LUID: {luid}")
            return

        disconnected_clients = []
        for client in self.clients:
            try:
                if not self.send_layout(client, luid):
                    disconnected_clients.append(client)
            except Exception as e:
                self.logger.warning(f"Client disconnected during broadcast: {e}")
                disconnected_clients.append(client)

        # Clean up disconnected clients
        for client in disconnected_clients:
            self.remove_client(client)

    def handle_client_message(self, client: socket.socket, data: str):
        """
        Process incoming message from client

        Args:
            client: Client socket
            data: Received message data
        """
        try:
            data = data.strip('\0').strip()
            if not data:
                return

            self.logger.info(f"Received from client: {data[:100]}...")

            # Try to parse as XML
            try:
                root = ET.fromstring(data)

                # Handle layout requests
                if root.tag == 'LayoutRequest':
                    luid = root.get('luid', 'mainLuid')
                    self.send_layout(client, luid)

                # Handle refresh requests
                elif root.tag == 'ISISRefresh':
                    action = root.get('action', 'reset')
                    if action == 'reset':
                        self.send_layout(client, 'mainLuid')

                # Handle layout replacement (from GMXBuilder save mode)
                elif root.tag == 'ISISRecord':
                    ruid = root.get('ruid')
                    if ruid == 'LM_REPLACE':
                        # Extract layout from record
                        for field in root.findall('Field'):
                            if field.get('fid') == 'layout_xml':
                                layout_xml = field.get('value', '')
                                luid = root.get('target_luid', 'mainLuid')
                                if self.add_layout(luid, layout_xml):
                                    self.broadcast_layout(luid)

                else:
                    self.logger.info(f"Unhandled message type: {root.tag}")

            except ET.ParseError:
                # Handle non-XML messages (control commands)
                if data.startswith('GET_LAYOUT:'):
                    luid = data.split(':', 1)[1] if ':' in data else 'mainLuid'
                    self.send_layout(client, luid)
                elif data == 'LIST_LAYOUTS':
                    layouts = json.dumps(self.list_layouts())
                    client.send(f"LAYOUTS:{layouts}\0".encode('utf-8'))
                else:
                    self.logger.info(f"Unhandled non-XML message: {data[:50]}...")

        except Exception as e:
            self.logger.error(f"Error handling client message: {e}")

    def handle_client(self, client_socket: socket.socket, address: tuple):
        """
        Handle individual client connection

        Args:
            client_socket: Client socket
            address: Client address tuple
        """
        self.logger.info(f"New client connected from {address}")
        self.clients.append(client_socket)

        try:
            # Send initial layout
            self.send_layout(client_socket, 'mainLuid')

            # Handle client messages
            buffer = ""
            while self.running:
                try:
                    data = client_socket.recv(4096).decode('utf-8')
                    if not data:
                        break

                    buffer += data

                    # Process complete messages (terminated by null character)
                    while '\0' in buffer:
                        message, buffer = buffer.split('\0', 1)
                        if message.strip():
                            self.handle_client_message(client_socket, message)

                except socket.timeout:
                    continue
                except Exception as e:
                    self.logger.warning(f"Client communication error: {e}")
                    break

        except Exception as e:
            self.logger.error(f"Error handling client {address}: {e}")
        finally:
            self.remove_client(client_socket)
            self.logger.info(f"Client {address} disconnected")

    def remove_client(self, client_socket: socket.socket):
        """Remove client from active clients list"""
        try:
            if client_socket in self.clients:
                self.clients.remove(client_socket)
            client_socket.close()
        except Exception as e:
            self.logger.warning(f"Error removing client: {e}")

    def start_server(self):
        """Start the layout server"""
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.settimeout(1.0)  # Allow periodic checks
            self.server_socket.bind((self.host, self.port))
            self.server_socket.listen(5)

            self.running = True
            self.logger.info(f"Layout server started on {self.host}:{self.port}")

            while self.running:
                try:
                    client_socket, address = self.server_socket.accept()
                    client_socket.settimeout(30.0)  # 30 second timeout for client operations

                    # Handle client in separate thread
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, address),
                        daemon=True
                    )
                    client_thread.start()

                except socket.timeout:
                    continue
                except Exception as e:
                    if self.running:
                        self.logger.error(f"Server error: {e}")

        except Exception as e:
            self.logger.error(f"Failed to start server: {e}")
        finally:
            self.stop_server()

    def stop_server(self):
        """Stop the layout server"""
        self.logger.info("Stopping layout server...")
        self.running = False

        # Close all client connections
        for client in self.clients[:]:
            self.remove_client(client)

        # Close server socket
        if self.server_socket:
            try:
                self.server_socket.close()
            except Exception as e:
                self.logger.warning(f"Error closing server socket: {e}")

        self.logger.info("Layout server stopped")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='GMX Layout Server')
    parser.add_argument('--host', default='localhost', help='Server host (default: localhost)')
    parser.add_argument('--port', type=int, default=12345, help='Server port (default: 12345)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose logging')

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Create and start server
    server = LayoutServer(args.host, args.port)

    try:
        server.start_server()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        server.stop_server()


if __name__ == '__main__':
    main()
