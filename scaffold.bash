#!/usr/bin/env bash

set -e

SOLUTION_NAME="Spotter"

echo "Creating solution folder..."
mkdir $SOLUTION_NAME
cd $SOLUTION_NAME

echo "Creating solution..."
dotnet new sln -n $SOLUTION_NAME

echo "Creating projects..."

# Web API
dotnet new webapi -n Spotter.WebAPI --use-controllers

# Services layer
dotnet new classlib -n Spotter.Services

# Model layer
dotnet new classlib -n Spotter.Model

echo "Adding projects to solution..."
dotnet sln add Spotter.WebAPI/Spotter.WebAPI.csproj
dotnet sln add Spotter.Services/Spotter.Services.csproj
dotnet sln add Spotter.Model/Spotter.Model.csproj

echo "Adding project references..."

# WebAPI → Services
dotnet add Spotter.WebAPI reference Spotter.Services

# Services → Model
dotnet add Spotter.Services reference Spotter.Model

echo "Adding EF Core packages..."

# ---- EF Core in Services (DbContext lives here) ----
dotnet add Spotter.Services package Microsoft.EntityFrameworkCore
dotnet add Spotter.Services package Microsoft.EntityFrameworkCore.SqlServer

# ---- EF Core Design tools in WebAPI (for migrations) ----
dotnet add Spotter.WebAPI package Microsoft.EntityFrameworkCore.Design

echo "Adding Scalar (OpenAPI UI) to WebAPI..."

dotnet add Spotter.WebAPI package Scalar.AspNetCore

echo "Creating recommended folders..."

mkdir -p Spotter.WebAPI/Controllers
mkdir -p Spotter.WebAPI/Middlewares
mkdir -p Spotter.WebAPI/Extensions

mkdir -p Spotter.Services/Interfaces
mkdir -p Spotter.Services/Implementations
mkdir -p Spotter.Services/Database


mkdir -p Spotter.Model/Responses
mkdir -p Spotter.Model/Requests
mkdir -p Spotter.Model/SearchObjects
mkdir -p Spotter.Model/Enums

echo "Done!"
echo "Next steps:"
echo "1) Add DbContext in Spotter.Services/Data"
echo "2) Register DbContext in WebAPI Program.cs"
echo "3) Configure Scalar in WebAPI"

echo "Open Spotter2.sln in your IDE."
