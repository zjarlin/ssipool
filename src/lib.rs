//! SSIPool 的 SSI 研究入口：时钟预检、双端启动准入与存储容量核算。
pub mod config;
mod digest;
pub mod placement;
pub mod ssi;
pub mod ssi_launch;
pub mod storage;
mod transport;
