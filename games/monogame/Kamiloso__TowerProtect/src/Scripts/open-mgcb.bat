@echo off
pushd "%~dp0..\TowerProtect"
dotnet mgcb-editor "Content\Content.mgcb"
popd