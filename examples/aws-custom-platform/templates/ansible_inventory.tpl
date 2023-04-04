[managers]
%{ for idx in mgr_idxs ~}
manager${idx} ansible_host=${mgr_user}@${mgr_hosts[idx].public_ip} ansible_ssh_private_key_file=${key_file}
%{ endfor ~}

[workers]
%{ for idx in wkr_idxs ~}
worker${idx} ansible_host=${wkr_user}@${wkr_hosts[idx].public_ip} ansible_ssh_private_key_file=${key_file}
%{ endfor ~}

[msrs]
%{ for idx in msr_idxs ~}
msr${idx} ansible_host=${msr_user}@${msr_hosts[idx].public_ip} ansible_ssh_private_key_file=${key_file}
%{ endfor ~}

[windows]
%{ for idx in win_wkr_idxs ~}
win${idx} ansible_host=${win_wkr_hosts[idx].public_ip}
%{ endfor ~}

[windows:vars]
ansible_user=administrator
ansible_password=${win_passwd}
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore

[linux:children]
managers
workers
msrs
