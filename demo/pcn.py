import tkinter as tk
import tkinter.messagebox
from tkinter import ttk
import json
import os
from web3.auto import w3
from web3 import Web3

# Define the application class with improved UI
class PaymentChannel:
    def __init__(self, root):
        self.root = root
        self.root.title("Off-Chain Payment Channel")
        
        self.root.geometry('600x450')
        style = ttk.Style()
        style.theme_use('clam')
        self.notebook = ttk.Notebook(root)
        self.notebook.pack(expand=True, fill='both')  # 让Notebook扩展和填充窗口
        
        # Create Tabs
        self.tab_send = ttk.Frame(self.notebook)
        self.tab_receive = ttk.Frame(self.notebook)
        self.tab_redeem = ttk.Frame(self.notebook)
        
        self.notebook.add(self.tab_send, text='Send')
        self.notebook.add(self.tab_receive, text='Receive')
        self.notebook.add(self.tab_redeem, text='Redeem')
        
        self.setup_send_tab(self.tab_send)
        self.setup_receive_tab(self.tab_receive)
        self.setup_redeem_tab(self.tab_redeem)

    def clean_bytes_list(self, bytes_list_str):
        # Remove whitespace and split by commas
        bytes_list = bytes_list_str.replace(" ", "").replace('"',"").strip("[]").split(",")
        # Filter out empty strings just in case
        bytes_list = [item for item in bytes_list if item]
        return bytes_list
    
    def sign_with_pk(self, seqNum, sender_balance, recipent_balance, hash_list, private_key):
        # Caculate the hash of message
        message_hash = Web3.solidity_keccak(['uint256', 'uint256', 'uint256', 'bytes32[]'], [int(seqNum), int(sender_balance), int(recipent_balance), hash_list])
        # Sign the message
        signed_message = w3.eth.account.signHash(message_hash, private_key=private_key)
        return signed_message.signature.hex()
    
    def setup_send_tab(self, tab):
        ttk.Label(tab, text="Sequence Number:").pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        self.suq_num_entry = ttk.Entry(tab)
        self.suq_num_entry.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        ttk.Label(tab, text="Sender Balance:").pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        self.sender_balance_entry = ttk.Entry(tab)
        self.sender_balance_entry.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        ttk.Label(tab, text="Recipient Balance:").pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        self.recipient_balance_entry = ttk.Entry(tab)
        self.recipient_balance_entry.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        ttk.Label(tab, text="Hash List:").pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        self.hash_list_entry = ttk.Entry(tab)
        self.hash_list_entry.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        ttk.Label(tab, text="Private Key:").pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        self.private_key_entry = ttk.Entry(tab)
        self.private_key_entry.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        ttk.Button(tab, text="Send", command=self.send).pack(side=tk.TOP, fill=tk.X, padx=5, pady=15)
    
    def setup_receive_tab(self, tab):
        self.label_seq_num = ttk.Label(tab, text="Sequence Number:")
        self.label_seq_num.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        self.label_sender_balance = ttk.Label(tab, text="Sender Balance:")
        self.label_sender_balance.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        self.label_recipient_balance = ttk.Label(tab, text="Recipient Balance:")
        self.label_recipient_balance.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        self.label_hash_list = ttk.Label(tab, text="Hash List:")
        self.label_hash_list.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        ttk.Button(tab, text="Receive", command=self.receive).pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
    
    def setup_redeem_tab(self, tab):
        ttk.Label(tab, text="Preimage List:").pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        self.preimage_list_entry = ttk.Entry(tab)
        self.preimage_list_entry.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        ttk.Label(tab, text="Private Key:").pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        self.redeem_with_pk_entry = ttk.Entry(tab)
        self.redeem_with_pk_entry.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        ttk.Button(tab, text="Redeem", command=self.redeem).pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
    
    def send(self):
        hash_list = self.clean_bytes_list(self.hash_list_entry.get())
        new_data = {
            "sequence_number": self.suq_num_entry.get(),
            "sender_balance": self.sender_balance_entry.get(),
            "recipient_balance": self.recipient_balance_entry.get(),
            "hash_list": hash_list,
            "sender_signature": self.sign_with_pk(self.suq_num_entry.get(), self.sender_balance_entry.get(), self.recipient_balance_entry.get(), hash_list, self.private_key_entry.get())
        }
        # Write the data to the file
        with open('send_data.json', 'w') as file:
            json.dump(new_data, file)

    def receive(self):
        # Check the file exists or not
        assert os.path.exists('send_data.json'), "Send file not exists!"
        with open('send_data.json', 'r') as file:
            new_data = json.load(file)

        # Check the received data
        if os.path.exists('received_data.json'):
            with open('received_data.json', 'r') as file:
                try:
                    data = json.load(file)
                except:
                    data = []
        else:
            data = []

        # check max seq_num of current file
        max_seq_num = 0
        for d in data:
            max_seq_num = max(max_seq_num, int(d["sequence_number"]))
        if int(new_data["sequence_number"]) <= max_seq_num:
            tk.messagebox.askquestion(title='Error', message='Receive fail! New Sequence Number is lower!')
        # add new data to the received_data
        data.append(new_data)
        with open("received_data.json", "w") as file:
            data = json.dump(data, file)
        self.label_seq_num.config(text=f"Sequence Number: {new_data.get('sequence_number', 'N/A')}")
        self.label_sender_balance.config(text=f"Sender Balance: {new_data.get('sender_balance', 'N/A')}")
        self.label_recipient_balance.config(text=f"Recipient Balance: {new_data.get('recipient_balance', 'N/A')}")
        self.label_hash_list.config(text=f"Hash List: {new_data.get('hash_list', 'N/A')}")

    def redeem(self):
        assert os.path.exists('received_data.json'), "Received file not exists!"
        with open("received_data.json", "r") as file:
            data = json.load(file)

        max_seq_num = 0
        for d in data:
            if int(d["sequence_number"]) > max_seq_num:
                max_data = d
        max_data["recipient_signature"] = self.sign_with_pk(max_data["sequence_number"], max_data["sender_balance"], 
                                                            max_data["recipient_balance"], max_data["hash_list"], self.redeem_with_pk_entry.get())
        max_data["secret"] = self.clean_bytes_list(self.preimage_list_entry.get())
        with open("redeemed_data.json", "w") as file:
            json.dump(max_data, file)

root = tk.Tk()
app = PaymentChannel(root)
root.mainloop()