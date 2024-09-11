#!/bin/bash
# Update the package list and install necessary packages
apt update
apt install -y tmux build-essential pkg-config libssl-dev git curl

# Clone the repository
git clone -b benchmarker_v2.0 https://github.com/tig-foundation/tig-monorepo.git
cd tig-monorepo
git config --global user.email "neo250376@gmail.com"
git config --global user.name "neo250376"
git pull --no-edit --no-rebase https://github.com/tig-foundation/tig-monorepo.git vehicle_routing/clarke_wright_super
git pull --no-edit --no-rebase https://github.com/tig-foundation/tig-monorepo.git vector_search/optimax_search
git pull --no-edit --no-rebase https://github.com/tig-foundation/tig-monorepo.git knapsack/quick_knap
git pull --no-edit --no-rebase https://github.com/tig-foundation/tig-monorepo.git satisfiability/sat_optima

cd /app

# Install rustup and cargo
bash -c '
curl --proto =https --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"
cd /app/tig-monorepo/tig-benchmarker
ALGOS_TO_COMPILE="satisfiability_sat_optima vehicle_routing_clarke_wright_super knapsack_quick_knap vector_search_optimax_search"
cargo fix --lib -p tig-algorithms --allow-dirty
cargo build -p tig-benchmarker --release --no-default-features --features "standalone ${ALGOS_TO_COMPILE}"
'

# Switch to the target release directory
cd /app/tig-monorepo/target/release

# Select algorithms to benchmark
SELECTED_ALGORITHMS='{"vehicle_routing":"clarke_wright_super", "vector_search":"optimax_search", "knapsack":"quick_knap", "satisfiability":"sat_optima"}'

# Calculate the number of workers (number of threads x 8)
NUM_THREADS=$(nproc)
NUM_WORKERS=$((NUM_THREADS))

# Export the variables so they are available to the tmux session
# Start a new tmux session
tmux new-session -d -s TIG

# Send the export commands and the command to run the benchmarker
tmux send-keys -t TIG "export SELECTED_ALGORITHMS='$SELECTED_ALGORITHMS'" C-m
tmux send-keys -t TIG "export NUM_WORKERS='$NUM_WORKERS'" C-m
tmux send-keys -t TIG "./tig-benchmarker 0x5beb545225a781d582d63fca242347b7f6bff14e 9b32bc17e6fb49a2630c031b3e1cdb8b '$SELECTED_ALGORITHMS' --workers $NUM_WORKERS --master 195.26.252.56" C-m
