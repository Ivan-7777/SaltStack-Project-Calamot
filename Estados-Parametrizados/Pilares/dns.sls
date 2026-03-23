dns:
  recursion: yes
  allow_query: "192.168.0.0/22; 10.2.0.0/16; 10.66.66.0/24"
  listen_on: []         
  forwarders:
    - 8.8.8.8
    - 8.8.4.4
  zones:
    internal.local:
      type: master
      allow_transfer: none
    example.local:       
      type: master
      allow_transfer: none
  hosts:
    ns1:
      ip: ""            
    www:
      ip: ""            
    mail:
      ip: ""            
    vpn:
      ip: ""            
