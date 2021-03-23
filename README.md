# GoogleHomeAPI
This is an unofficial API to communicate to Google Smart Speakers. I only use(d) this API to get upcoming alarms from my NestHub however it can be used to do many different tasks.

---

## Credit
First of all credit where credit is due: This project is a mix of information found by Rithvik Vibhu found on his [Github](https://github.com/rithvikvibhu/GHLocalApi) and his [website](https://rithvikvibhu.github.io/GHLocalApi/). **Most of the code is copied one-to-one from him.** I only edited stripped it down and collected everything I needed to make it work.

----
## Setup


First of all I recommend to read the [existing documentation of Rithvik Vibhu](https://rithvikvibhu.github.io/GHLocalApi/#section/Google-Home-Local-API/Example). You need this prior knowledge to understand what I am doing!

### Getting the fingers dirty
1. Get the access token
   For this I found [this script](https://gist.github.com/rithvikvibhu/952f83ea656c6782fbd0f1645059055d) which is included and called get_master_and_access_tokens.py in this repository. You need to add your google credentials to the start of the script and install **version 0.4.2** from gpsoauth with `sudo pip install -Iv gpsoauth==0.4.2`. With the newer version 0.4.3 I did have some issues (`TypeError: __new__() takes at least 2 arguments (1 given)...`) so I recommend sticking to 0.4.2
   If you start the script with `python get_master_and_access_tokens.py` it returns an master token and an access token; you can ignore the former one. The access token is the interesting part and starts with `ya29.`
    ```
    # Like this command line?
    # Check out my config at https://github.com/Trysupe/bashrc/blob/6a135981345cefae63ccdd8c8910b41d099fedf1/default/command_promt
    ┌─[21:50:55]-[:)]-[user@host]-[/tmp/GoogleHomeApi/ (master)]

    └──> python get_master_and_access_tokens.py

    Master Token gets created...
    aas_et/brMXXXXXXXXXXXXXXTyrsProcI=

    Access Token gets created...
    ya29.a0SMBXXXXXXXXXXXXXXXXXaEC8N6O6
    ```

2. Get the auth token
   This is an token which is needed to talk to the API of google and changes frequently. To achieve this I used [grpcurl](https://github.com/fullstorydev/grpcurl) as Rithvik Vibhu instructed.
   - I had to clone the repository and make a compiled and executed version of it. I think this was possible by navigating to the source directory and using `go install` (given you have `go` installed)
   - However I did this already and included the output in the file get_local_auth_token.go so you don't have to =).

    You can run it just like a bash script `./get_local_auth_token.go` although I don't know if having `go` installed is a requirement. If so you can find some instructions [here](https://golang.org/doc/install).
    For the parameters of the script please refer to the guide of Rithvik Vibhu. You do need a proto file which is also included in this repository.
    The script will return many auth tokens. Note down the one you need.

3. Access the API (finally)
   Now you can access the API of the device you are trying to get information from.
   This can be done with a simple `curl` command. For example you can get all alarms by executing
   ```
   NestHubIP="192.168.XXX.XXX"
   curl -H "cast-local-authorization-token: $local_auth_token" --insecure https://$NestHubIP:8443/setup/assistant/alarms
   ```
   This will return an array of alarms you can parse and use for your needs.

## Example

As stated above the only need for me was to get future alarms of my NestHub to send this information to [openHAB](https://www.openhab.org/). For this I included the whole script to achieve this in `get_alarms_and_send_to_openhab.sh`.

-----

## Questions?

If you have any questions feel free to [contact me](fs@felix-schneider.org) or open an issue. Of course you may add a merge request to improve this documentation if you think it could be improved.
Moreover you may send an email to [Rithvik Vibhu](rithvikvibhu@gmail.com).