const CHAIN={id:968,hex:"0x3c8",name:"BOT Chain Testnet",symbol:"BOT",rpc:"https://rpc.bohr.life",explorer:"https://scan.bohr.life",website:"https://botchain.ai"};
// TODO: replace with your deployed MediVault address
const CONTRACT_ADDRESS="0xA8cB7a592453f6ac164439235f4f477495b78995";
const ABI=["function admin() view returns (address)","function hospitals(address) view returns (string name,bool active)","function addHospital(address h,string name)","function removeHospital(address h)","function hospitalCount() view returns (uint256)","function hospitalAt(uint256 i) view returns (address,string,bool)","function grant(address doctor,uint256 daysValid)","function revoke(address doctor)","function myDoctors() view returns (address[],uint256[])","function addRecord(address patient,string category,string fileHash,string note)","function recordCount(address patient) view returns (uint256)","function getRecord(address patient,uint256 id) view returns (address,string,string,string,uint256)","function hasAccess(address patient,address viewer) view returns (bool)"];
let signer,account,vault;
const $=s=>document.querySelector(s);
const short=a=>a.slice(0,6)+"…"+a.slice(-4);
const when=t=>new Date(Number(t)*1000).toLocaleString();
const esc=s=>String(s).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
let tt;function toast(m,err){const t=$("#toast");t.className=err?"err":"";t.innerHTML=m;t.style.display="block";clearTimeout(tt);tt=setTimeout(()=>t.style.display="none",err?6000:5000)}
async function ensureChain(){
  try{await ethereum.request({method:"wallet_switchEthereumChain",params:[{chainId:CHAIN.hex}]})}
  catch(e){if(e.code!==4902&&e.code!==-32603)throw e;
    await ethereum.request({method:"wallet_addEthereumChain",params:[{chainId:CHAIN.hex,chainName:CHAIN.name,nativeCurrency:{name:"BOT",symbol:CHAIN.symbol,decimals:18},rpcUrls:[CHAIN.rpc],blockExplorerUrls:[CHAIN.explorer]}]})}
}
async function connect(){
  if(!window.ethereum)return toast("Install MetaMask or another EVM wallet.",1);
  try{
    await ensureChain();
    const p=new ethers.BrowserProvider(ethereum);await p.send("eth_requestAccounts",[]);
    signer=await p.getSigner();account=await signer.getAddress();$("#wbtn").textContent=short(account);
    if(/^0x0+$/.test(CONTRACT_ADDRESS))return toast("Set CONTRACT_ADDRESS in js/app.js",1);
    vault=new ethers.Contract(CONTRACT_ADDRESS,ABI,signer);
    document.dispatchEvent(new Event("ready"));
  }catch(e){toast(e.shortMessage||e.message,1)}
}
async function tx(p,msg){
  try{const t=await p;toast("Transaction sent… waiting for confirmation");await t.wait();
    toast(msg+' ✓ <a target="_blank" href="'+CHAIN.explorer+'/tx/'+t.hash+'">View on explorer</a>');return true}
  catch(e){toast(e.reason||e.shortMessage||e.message,1);return false}
}
function needWallet(el){el.innerHTML='<div class="notice">Connect your wallet to continue.</div>'}
addEventListener("load",()=>{$("#wbtn").onclick=connect;
  if(window.ethereum)ethereum.request({method:"eth_accounts"}).then(a=>a.length&&connect())});
