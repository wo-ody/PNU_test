const dir = "/milk&meat/itemData";
const dirAuc = "/milk&meat/aucData";

    async function buildItemData(_itemId, _fish, _kg, _count, _from, _CIDArr){
                var metadata = new Object();
                var descript = "This is metadata of " + _fish;
                var userAccounts = await web3.eth.getAccounts();

                
                metadata.name = _fish;
                metadata.weight = _kg.toString();
                metadata.amount = _count.toString();
                metadata.origin = _from.toString();
                metadata.image = _CIDArr[0];  
                metadata.id = _itemId.toString();
                metadata.producer = userAccounts[0].toString();
                metadata.description = descript;              

                //console.log(jsonData);
                
                return JSON.stringify(metadata);
        }

        async function buildAuctionData(_auctionId, _itemId, _auctionTitle, _startPrice, _winningPrice, 
            _stock, _from, _to, _shippingFrom, _shippingTo, _startTime, _blockDeadLine){
                var auction = new Object();
                var descript = "This is auction data of "+_auctionTitle;
                auction.auctionId = _auctionId;
                auction.itemId = _itemId;
                auction.auctionTitle = _auctionTitle;
                auction.startPrice = _startPrice;
                auction.winningPrice = _winningPrice;
                auction.stock = _stock;
                auction.shippingFrom = _shippingFrom;
                auction.shippingTo = _shippingTo;
                auction.startTime = _startTime;
                auction.blockDeadLine = _blockDeadLine;
                auction.seller = _from;
                auction.buyer = _to;
                auction.description = descript;
    
                return JSON.stringify(auction);
            }
            async function buildNewAuctionData(_prevAuction, _bidderInfo){
                    var auction = new Object();
                    var bidderInfo = new Object();

                    console.log(auction);
                    console.log(bidderInfo);
                
                    auction = _prevAuction;
                    bidderInfo = _bidderInfo;
                    auction.buyer = _bidderInfo.from;
                    auction.shippingTo = _bidderInfo.shippingTo;
                    auction.winningPrice = _bidderInfo.amount;

        
                    return JSON.stringify(auction);
                }

        async function getDirCID(_dir){

            var binary = await ipfs.files.stat(_dir)
            var result = binary.cid.toString();
            console.log(result);

            return result;
        }

        async function mkdir(_dir){
            const ipfs = await Ipfs.create();
            //await ipfs.files.mkdir(dirAuc);
            console.log((await ipfs.files.stat(_dir)).cid.toString());
        }

        async function buildGoldData(ipfs, _CIDArr){
            //await ipfs.files.mkdir(dir);

            var metadata = new Object();
            var weight = new Object();
            var producer = new Object();
            var descript = "This is metadata of " + "Meat&Milk Token";
            var userAccounts = await web3.eth.getAccounts();

                metadata.name = "MMT";
                metadata.amount = 10**18;
                metadata.image = _CIDArr[0];  
                metadata.id = 0;
                metadata.producer = userAccounts[0];
                metadata.description = descript;
                
                
                var jdata = JSON.stringify(metadata);

                console.log(jdata);

                var buf = new TextEncoder().encode(jdata);

                console.log(jdata);

                var idx = (0).toString(16);
                idx = idx.padStart(64,'0');

                await ipfs.files.write(dir+'/'+idx+'.json', buf, { create: true });


                var readData = await readMetadata(0, dir,ipfs);

                dirCID = await ipfs.files.stat(dir);
                dirCID = dirCID.cid.toString();
                console.log(dirCID);
                
                return dirCID;

        }

        async function readMetadata(_id, _dir, ipfs){
            var pathIdx = _id.toString(16);
            pathIdx = pathIdx.padStart(64,'0');
            var path = _dir+"/"+pathIdx+".json";
            console.log(path);
            var len = 0;
            var chunks = [];
            for await(var chunk of ipfs.files.read(path)){
                chunks.push(chunk);
                len += chunk.length;
            }
            var cat = new Uint8Array(len);
            var idx = 0;
            for (chunk of chunks){
                cat.set(chunk, idx);
                idx += chunk.length;
            }
            console.log(cat)
            var jsonData = JSON.parse(new TextDecoder().decode(cat).toString());

            console.log(jsonData);

            return jsonData;
        }

     