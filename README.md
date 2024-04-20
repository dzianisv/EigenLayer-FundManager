# EigenLayer FundManager

![](docs/SystemDesign.png)


## Dev


### Environment


1. Install foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
```

2. Pull repo and submodules `git submodule update --init --recursive`

3. Go to contracts and run `cd contracts; forge install; forge bulid` or `forge test`


### How to deploy contract

1. `cd contracts`
2. Copy `.env.example` to `.env` and set values
3. Run `./bin/deploy.sh`


### Web
1. `cd webui && python3 -m http.server`
2. Open [localhost:8000](http://localhost:8000)


