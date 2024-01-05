#!/bin/bash


export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
RETURN=""
ADDR_OWNER=$(seid keys show pepe -a --keyring-backend test)
WALLET="--from pepe"
NODE="https://sei-rpc.polkachu.com:443"
CHAIN_ID="pacific-1"
NODECHAIN="--node $NODE --chain-id $CHAIN_ID"
TXFLAG="$NODECHAIN --gas=10000000 --fees=10000000usei --broadcast-mode=block --keyring-backend test -y"


Execute() {
    CMD=$1
    if  [[ $CMD == cd* ]] ; then
        $CMD > ~/out.log
        RETURN=$(cat ~/out.log)
    else
        RETURN=$(eval $CMD)
    fi
}
Upload() {
    CATEGORY=$1
    Execute "seid tx wasm store release/$CATEGORY".wasm" $WALLET $TXFLAG --output json | jq -r '.txhash'"
    UPLOADTX=$RETURN
    echo "Upload txHash: "$UPLOADTX


    CODE_ID=""
    while [[ $CODE_ID == "" ]]
    do
        sleep 3
        Execute "seid query tx --type=hash $UPLOADTX $NODECHAIN --output json | jq -r '.logs[0].events[-1].attributes[0].value'"
        CODE_ID=$RETURN
    done


    echo "$CATEGORY Contract Code_id: "$CODE_ID
    echo $CODE_ID > data/code_$CATEGORY
}
InstantiateCW20() {
    CATEGORY='cw20_base'
    echo "Instantiate Contract "$CATEGORY


    #read from FILE_CODE_ID
    CODE_ID=$(cat data/code_$CATEGORY)
    echo "Code id: " $CODE_ID


    Execute "seid tx wasm instantiate $CODE_ID '{\"name\":\"$TOKEN_NAME\",\"symbol\":\"$SYMBOL\",\"decimals\":18,\"initial_balances\":[{\"address\":\"'$ADDR_OWNER'\",\"amount\":\"500000000000000000000000000\"}],\"mint\":{\"minter\":\"'$ADDR_OWNER'\"},\"marketing\":{\"marketing\":\"'$ADDR_OWNER'\",\"logo\":{\"url\":\"https://pepeonsei.com/assets/images/logo/pepefavicon.png\"}}}' --label \"$TOKEN_NAME\" --admin $ADDR_OWNER $WALLET $TXFLAG --output json | jq -r '.txhash'"
    TXHASH=$RETURN


    echo "Transaction hash = $TXHASH"
    CONTRACT_ADDR=""
    while [[ $CONTRACT_ADDR == "" ]]
    do
        sleep 3
        Execute "seid query tx $TXHASH $NODECHAIN --output json | jq -r '.logs[0].events[0].attributes[0].value'"
        CONTRACT_ADDR=$RETURN
    done
    echo "Contract Address: " $CONTRACT_ADDR
    echo $CONTRACT_ADDR > data/contract_$CATEGORY
}


CATEGORY=cw20-base
Execute "cd $CATEGORY"
mkdir "data"
mkdir "release"
Execute "pwd"
rm -rf target
Execute "RUSTFLAGS='-C link-arg=-s' cargo wasm"
Execute "cp ./target/wasm32-unknown-unknown/release/$CATEGORY.wasm release/"


Upload $CATEGORY


# This function will be used later.


# InstantiateCW20
