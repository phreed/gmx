#!/usr/bin/env python3
"""
GMX Data Server Example

This is a reference implementation of a data server for the GMX client framework.
The server manages record and collection data, and sends updates to connected GMX
clients via XML socket connections.

Features:
- Socket-based XML message handling
- Record storage and management by RUID
- Collection storage and management by CUID
- Real-time data updates and broadcasting
- Client connection management
- Example data definitions
- Simulated real-time data feeds

Usage:
    python data_server.py [--host HOST] [--port PORT]

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
import json
import random
from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
import uuid


class Record:
    """Represents a single data record with fields"""

    def __init__(self, ruid: str):
        self.ruid = ruid
        self.fields: Dict[str, str] = {}
        self.attributes: List[Dict[str, str]] = []
        self.last_updated = datetime.now()

    def set_field(self, fid: str, value: str):
        """Set field value"""
        self.fields[fid] = value
        self.last_updated = datetime.now()

    def get_field(self, fid: str) -> Optional[str]:
        """Get field value"""
        return self.fields.get(fid)

    def add_attribute(self, ruid: str, fid: str, send: bool = True):
        """Add cross-record attribute reference"""
        self.attributes.append({
            'ruid': ruid,
            'fid': fid,
            'send': str(send).lower()
        })

    def to_xml(self) -> str:
        """Convert record to XML format"""
        fields_xml = ""
        for fid, value in self.fields.items():
            # Escape XML characters
            escaped_value = value.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            fields_xml += f'<Field fid="{fid}" value="{escaped_value}"/>'

        attributes_xml = ""
        for attr in self.attributes:
            attributes_xml += f'<Attribute ruid="{attr["ruid"]}" fid="{attr["fid"]}" send="{attr["send"]}"/>'

        return f'<ISISRecord ruid="{self.ruid}">{fields_xml}{attributes_xml}</ISISRecord>'


class Collection:
    """Represents a collection of record references"""

    def __init__(self, cuid: str):
        self.cuid = cuid
        self.ruid_list: List[Dict[str, str]] = []
        self.last_updated = datetime.now()

    def add_ruid(self, ruid: str, select: str = "last", ref: Optional[str] = None):
        """Add record reference to collection"""
        ruid_entry = {'ruid': ruid, 'select': select}
        if ref:
            ruid_entry['ref'] = ref
        self.ruid_list.append(ruid_entry)
        self.last_updated = datetime.now()

    def remove_ruid(self, ruid: str):
        """Remove record reference from collection"""
        self.ruid_list = [r for r in self.ruid_list if r['ruid'] != ruid]
        self.last_updated = datetime.now()

    def clear(self):
        """Clear all record references"""
        self.ruid_list.clear()
        self.last_updated = datetime.now()

    def to_xml(self) -> str:
        """Convert collection to XML format"""
        ruid_xml = ""
        for ruid_entry in self.ruid_list:
            ref_attr = f' ref="{ruid_entry["ref"]}"' if 'ref' in ruid_entry else ''
            ruid_xml += f'<Ruid ruid="{ruid_entry["ruid"]}" select="{ruid_entry["select"]}"{ref_attr}/>'

        return f'<ISISCollection cuid="{self.cuid}"><RuidList>{ruid_xml}</RuidList></ISISCollection>'


class DataServer:
    """
    GMX Data Server implementation

    Manages record and collection data and serves updates to GMX clients via XML socket connections.
    """

    def __init__(self, host: str = 'localhost', port: int = 12346):
        self.host = host
        self.port = port
        self.records: Dict[str, Record] = {}
        self.collections: Dict[str, Collection] = {}
        self.clients: List[socket.socket] = []
        self.running = False
        self.server_socket: Optional[socket.socket] = None

        # Set up logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

        # Initialize default data
        self._initialize_default_data()

        # Start data simulation thread
        self.simulation_thread = None

    def _initialize_default_data(self):
        """Initialize default records and collections"""

        # Button record for simple layout
        button_record = Record("button_record")
        button_record.set_field("click_action", "")
        button_record.set_field("status_message", "Ready")
        button_record.set_field("click_count", "0")
        self.records["button_record"] = button_record

        # User form record
        user_form = Record("user_form_record")
        user_form.set_field("username", "")
        user_form.set_field("email", "")
        user_form.set_field("password", "")
        user_form.set_field("bio", "")
        user_form.set_field("selected_role", "user")
        user_form.set_field("account_type", "standard")
        user_form.set_field("submit_action", "")
        user_form.set_field("reset_action", "")
        user_form.set_field("cancel_action", "")
        user_form.set_field("form_valid", "false")
        self.records["user_form_record"] = user_form

        # Validation record
        validation_record = Record("validation_record")
        validation_record.set_field("status_message", "Please fill out the form")
        validation_record.set_field("validation_errors", "")
        self.records["validation_record"] = validation_record

        # System status record
        system_status = Record("system_status")
        system_status.set_field("status_text", "System Operational")
        system_status.set_field("status_icon", "success")
        system_status.set_field("uptime", "6h 30m 25s")
        system_status.set_field("memory_usage", "2.1 GB / 4.0 GB")
        system_status.set_field("current_time", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
        system_status.set_field("connection_status", "connected")
        self.records["system_status"] = system_status

        # Navigation data record
        nav_data = Record("navigation_data")
        nav_data.set_field("magnetic_heading", "045")
        nav_data.set_field("heading_display", "045° NE")
        nav_data.set_field("speed_display", "65.2 km/h")
        nav_data.set_field("turn_rate", "0.5")
        nav_data.set_field("turn_rate_display", "0.5°/s R")
        self.records["navigation_data"] = nav_data

        # User info record
        user_info = Record("user_info")
        user_info.set_field("display_name", "System Administrator")
        user_info.set_field("role", "Administrator")
        user_info.set_field("last_login", "2024-01-15 08:00:00")
        self.records["user_info"] = user_info

        # Initialize role options collection
        self._initialize_role_options()

        # Initialize system metrics collection
        self._initialize_system_metrics()

        # Initialize alerts collection
        self._initialize_alerts()

        self.logger.info(f"Initialized {len(self.records)} records and {len(self.collections)} collections")

    def _initialize_role_options(self):
        """Initialize role options collection and records"""

        # Create role records
        roles = [
            ("role_admin", "admin", "Administrator", "Full system access"),
            ("role_manager", "manager", "Manager", "Management access"),
            ("role_user", "user", "Standard User", "Standard user access"),
            ("role_guest", "guest", "Guest", "Limited read-only access"),
            ("role_operator", "operator", "System Operator", "Operational control"),
            ("role_analyst", "analyst", "Data Analyst", "Data analysis access")
        ]

        for ruid, role_id, display_name, description in roles:
            record = Record(ruid)
            record.set_field("role_id", role_id)
            record.set_field("display_name", display_name)
            record.set_field("description", description)
            record.set_field("active", "true")
            self.records[ruid] = record

        # Create role options collection
        role_collection = Collection("role_options")
        for ruid, _, _, _ in roles:
            role_collection.add_ruid(ruid, "last")
        self.collections["role_options"] = role_collection

    def _initialize_system_metrics(self):
        """Initialize system metrics collection and records"""

        metrics = [
            ("metric_cpu_usage", "CPU Usage", "15.3%", "Normal"),
            ("metric_memory_usage", "Memory Usage", "2.1 GB", "Normal"),
            ("metric_disk_io", "Disk I/O", "125 MB/s", "Normal"),
            ("metric_network_throughput", "Network Throughput", "1.2 Mbps", "Normal"),
            ("metric_db_connections", "DB Connections", "8", "Normal"),
            ("metric_active_users", "Active Users", "23", "Normal"),
            ("metric_response_time", "Avg Response Time", "125ms", "Normal"),
            ("metric_error_rate", "Error Rate", "0.02%", "Normal")
        ]

        for ruid, name, value, status in metrics:
            record = Record(ruid)
            record.set_field("metric_name", name)
            record.set_field("current_value", value)
            record.set_field("status", status)
            record.set_field("last_updated", datetime.now().strftime("%H:%M:%S"))
            self.records[ruid] = record

        # Create metrics collection
        metrics_collection = Collection("system_metrics")
        for ruid, _, _, _ in metrics:
            metrics_collection.add_ruid(ruid, "last")
        self.collections["system_metrics"] = metrics_collection

    def _initialize_alerts(self):
        """Initialize alerts collection and records"""

        alerts = [
            ("alert_mem_002", "Warning", "High memory usage detected", "14:25:32"),
            ("alert_net_004", "Warning", "Network latency increased", "14:15:45"),
            ("alert_disk_006", "Warning", "Low disk space on /data", "14:05:10")
        ]

        for ruid, severity, message, alert_time in alerts:
            record = Record(ruid)
            record.set_field("severity", severity)
            record.set_field("message", message)
            record.set_field("alert_time", alert_time)
            record.set_field("acknowledged", "false")
            record.set_field("resolved", "false")
            self.records[ruid] = record

        # Create alerts collection
        alerts_collection = Collection("alerts_list")
        for ruid, _, _, _ in alerts:
            alerts_collection.add_ruid(ruid, "last")
        self.collections["alerts_list"] = alerts_collection

    def add_record(self, record: Record):
        """Add or update a record"""
        self.records[record.ruid] = record
        self.logger.info(f"Added/updated record: {record.ruid}")

    def get_record(self, ruid: str) -> Optional[Record]:
        """Get record by RUID"""
        return self.records.get(ruid)

    def remove_record(self, ruid: str) -> bool:
        """Remove record by RUID"""
        if ruid in self.records:
            del self.records[ruid]
            self.logger.info(f"Removed record: {ruid}")
            return True
        return False

    def update_record_field(self, ruid: str, fid: str, value: str) -> bool:
        """Update a specific field in a record"""
        if ruid in self.records:
            self.records[ruid].set_field(fid, value)
            self.broadcast_record_update(ruid)
            return True
        return False

    def add_collection(self, collection: Collection):
        """Add or update a collection"""
        self.collections[collection.cuid] = collection
        self.logger.info(f"Added/updated collection: {collection.cuid}")

    def get_collection(self, cuid: str) -> Optional[Collection]:
        """Get collection by CUID"""
        return self.collections.get(cuid)

    def remove_collection(self, cuid: str) -> bool:
        """Remove collection by CUID"""
        if cuid in self.collections:
            del self.collections[cuid]
            self.logger.info(f"Removed collection: {cuid}")
            return True
        return False

    def broadcast_record_update(self, ruid: str):
        """Broadcast record update to all clients"""
        if ruid not in self.records:
            return

        message = self.records[ruid].to_xml() + '\0'
        self._broadcast_message(message)

    def broadcast_collection_update(self, cuid: str):
        """Broadcast collection update to all clients"""
        if cuid not in self.collections:
            return

        message = self.collections[cuid].to_xml() + '\0'
        self._broadcast_message(message)

    def _broadcast_message(self, message: str):
        """Broadcast message to all connected clients"""
        disconnected_clients = []

        for client in self.clients:
            try:
                client.send(message.encode('utf-8'))
            except Exception as e:
                self.logger.warning(f"Failed to send to client: {e}")
                disconnected_clients.append(client)

        # Clean up disconnected clients
        for client in disconnected_clients:
            self.remove_client(client)

    def handle_client_message(self, client: socket.socket, data: str):
        """Process incoming message from client"""
        try:
            data = data.strip('\0').strip()
            if not data:
                return

            self.logger.info(f"Received from client: {data[:100]}...")

            # Try to parse as XML
            try:
                root = ET.fromstring(data)

                # Handle record updates from client
                if root.tag == 'ISISRecord':
                    self._handle_record_message(root)

                # Handle collection updates from client
                elif root.tag == 'ISISCollection':
                    self._handle_collection_message(root)

                # Handle data requests
                elif root.tag == 'DataRequest':
                    self._handle_data_request(client, root)

                else:
                    self.logger.info(f"Unhandled message type: {root.tag}")

            except ET.ParseError:
                # Handle non-XML messages
                if data.startswith('GET_RECORD:'):
                    ruid = data.split(':', 1)[1] if ':' in data else ''
                    if ruid in self.records:
                        message = self.records[ruid].to_xml() + '\0'
                        client.send(message.encode('utf-8'))

                elif data.startswith('GET_COLLECTION:'):
                    cuid = data.split(':', 1)[1] if ':' in data else ''
                    if cuid in self.collections:
                        message = self.collections[cuid].to_xml() + '\0'
                        client.send(message.encode('utf-8'))

                elif data == 'LIST_RECORDS':
                    records = json.dumps(list(self.records.keys()))
                    client.send(f"RECORDS:{records}\0".encode('utf-8'))

                elif data == 'LIST_COLLECTIONS':
                    collections = json.dumps(list(self.collections.keys()))
                    client.send(f"COLLECTIONS:{collections}\0".encode('utf-8'))

        except Exception as e:
            self.logger.error(f"Error handling client message: {e}")

    def _handle_record_message(self, root: ET.Element):
        """Handle incoming record update message"""
        ruid = root.get('ruid')
        if not ruid:
            return

        # Get or create record
        if ruid not in self.records:
            self.records[ruid] = Record(ruid)

        record = self.records[ruid]

        # Update fields
        for field in root.findall('Field'):
            fid = field.get('fid')
            value = field.get('value', '')
            if fid:
                record.set_field(fid, value)

        # Handle special actions
        if ruid == "button_record":
            click_action = record.get_field("click_action")
            if click_action:
                # Increment click count
                count = int(record.get_field("click_count") or "0")
                count += 1
                record.set_field("click_count", str(count))
                record.set_field("status_message", f"Clicked {count} times!")
                record.set_field("click_action", "")  # Reset action

        elif ruid == "user_form_record":
            # Handle form submission
            submit_action = record.get_field("submit_action")
            if submit_action:
                username = record.get_field("username") or ""
                email = record.get_field("email") or ""
                if username and email:
                    # Update validation record
                    if "validation_record" in self.records:
                        self.records["validation_record"].set_field("status_message",
                            f"User {username} registered successfully!")
                        self.broadcast_record_update("validation_record")
                else:
                    if "validation_record" in self.records:
                        self.records["validation_record"].set_field("status_message",
                            "Please fill in required fields")
                        self.broadcast_record_update("validation_record")
                record.set_field("submit_action", "")  # Reset action

        # Broadcast update
        self.broadcast_record_update(ruid)

    def _handle_collection_message(self, root: ET.Element):
        """Handle incoming collection update message"""
        cuid = root.get('cuid')
        if not cuid:
            return

        # Get or create collection
        if cuid not in self.collections:
            self.collections[cuid] = Collection(cuid)

        collection = self.collections[cuid]

        # Process RUID list
        ruid_list = root.find('RuidList')
        if ruid_list is not None:
            for ruid_elem in ruid_list.findall('Ruid'):
                ruid = ruid_elem.get('ruid', '')
                select = ruid_elem.get('select', 'last')
                ref = ruid_elem.get('ref')

                if select == 'clear':
                    collection.clear()
                elif select == 'delete' and ruid:
                    collection.remove_ruid(ruid)
                elif ruid:
                    collection.add_ruid(ruid, select, ref)

        # Broadcast update
        self.broadcast_collection_update(cuid)

    def _handle_data_request(self, client: socket.socket, root: ET.Element):
        """Handle data request from client"""
        request_type = root.get('type')

        if request_type == 'initial':
            # Send all initial data
            for record in self.records.values():
                message = record.to_xml() + '\0'
                client.send(message.encode('utf-8'))

            for collection in self.collections.values():
                message = collection.to_xml() + '\0'
                client.send(message.encode('utf-8'))

    def _simulate_real_time_data(self):
        """Simulate real-time data updates"""
        while self.running:
            try:
                # Update system status
                if "system_status" in self.records:
                    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                    self.records["system_status"].set_field("current_time", current_time)
                    self.broadcast_record_update("system_status")

                # Update navigation data
                if "navigation_data" in self.records:
                    # Simulate changing heading
                    current_heading = int(self.records["navigation_data"].get_field("magnetic_heading") or "0")
                    new_heading = (current_heading + random.randint(-5, 5)) % 360
                    self.records["navigation_data"].set_field("magnetic_heading", str(new_heading))

                    # Update heading display
                    directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
                    direction = directions[int((new_heading + 22.5) / 45) % 8]
                    self.records["navigation_data"].set_field("heading_display", f"{new_heading:03d}° {direction}")

                    # Simulate turn rate
                    turn_rate = random.uniform(-2.0, 2.0)
                    self.records["navigation_data"].set_field("turn_rate", f"{turn_rate:.1f}")
                    direction_text = "R" if turn_rate > 0 else "L" if turn_rate < 0 else ""
                    self.records["navigation_data"].set_field("turn_rate_display", f"{abs(turn_rate):.1f}°/s {direction_text}")

                    self.broadcast_record_update("navigation_data")

                # Update system metrics
                for metric_id in ["metric_cpu_usage", "metric_memory_usage", "metric_response_time"]:
                    if metric_id in self.records:
                        # Simulate small changes in metrics
                        current_time = datetime.now().strftime("%H:%M:%S")
                        self.records[metric_id].set_field("last_updated", current_time)
                        self.broadcast_record_update(metric_id)

                time.sleep(10)  # Update every 10 seconds

            except Exception as e:
                self.logger.error(f"Error in data simulation: {e}")
                time.sleep(5)

    def handle_client(self, client_socket: socket.socket, address: tuple):
        """Handle individual client connection"""
        self.logger.info(f"New client connected from {address}")
        self.clients.append(client_socket)

        try:
            # Send initial data
            for record in self.records.values():
                message = record.to_xml() + '\0'
                client_socket.send(message.encode('utf-8'))

            for collection in self.collections.values():
                message = collection.to_xml() + '\0'
                client_socket.send(message.encode('utf-8'))

            # Handle client messages
            buffer = ""
            while self.running:
                try:
                    data = client_socket.recv(4096).decode('utf-8')
                    if not data:
                        break

                    buffer += data

                    # Process complete messages
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
        """Start the data server"""
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.settimeout(1.0)
            self.server_socket.bind((self.host, self.port))
            self.server_socket.listen(5)

            self.running = True
            self.logger.info(f"Data server started on {self.host}:{self.port}")

            # Start data simulation thread
            self.simulation_thread = threading.Thread(target=self._simulate_real_time_data, daemon=True)
            self.simulation_thread.start()

            while self.running:
                try:
                    client_socket, address = self.server_socket.accept()
                    client_socket.settimeout(30.0)

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
        """Stop the data server"""
        self.logger.info("Stopping data server...")
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

        self.logger.info("Data server stopped")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description='GMX Data Server')
    parser.add_argument('--host', default='localhost', help='Server host (default: localhost)')
    parser.add_argument('--port', type=int, default=12346, help='Server port (default: 12346)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose logging')

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Create and start server
    server = DataServer(args.host, args.port)

    try:
        server.start_server()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        server.stop_server()


if __name__ == '__main__':
    main()
