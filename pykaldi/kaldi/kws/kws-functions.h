// kws/kws-functions.h

// Copyright 2012  Johns Hopkins University (Author: Guoguo Chen)

// See ../../COPYING for clarification regarding multiple authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
// WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
// MERCHANTABLITY OR NON-INFRINGEMENT.
// See the Apache 2 License for the specific language governing permissions and
// limitations under the License.


#ifndef KALDI_KWS_KWS_FUNCTIONS_H_
#define KALDI_KWS_KWS_FUNCTIONS_H_

#include <vector>
#include <tuple>

#include "fst/encode.h"
#include "lat/kaldi-lattice.h"
#include "kws/kaldi-kws.h"

namespace kaldi {

// We store the time information of the arc into class "Interval". "Interval"
// has a public function "int32 Overlap(Interval interval)" which takes in
// another interval and returns the overlap of that interval and the current
// interval.
class Interval {
 public:
  Interval() {}
  Interval(int32 start, int32 end) : start_(start), end_(end) {}
  Interval(const Interval &interval) : start_(interval.Start()), end_(interval.End()) {}
  int32 Overlap(Interval interval) {
    return std::max<int32>(0, std::min(end_, interval.end_) -
                              std::max(start_, interval.start_));
  }
  int32 Start() const {return start_;}
  int32 End() const {return end_;}
  ~Interval() {}

 private:
  int32 start_;
  int32 end_;
};

// We define a function bool CompareInterval(const Interval &i1, const Interval
// &i2) to compare the Interval defined above. If interval i1 is in front of
// interval i2, then return true; otherwise return false.
bool CompareInterval(const Interval &i1,
                     const Interval &i2);

// This function clusters the arcs with same word id and overlapping time-spans.
// Examples of clusters:
// 0 1 a a (0.1s ~ 0.5s) and 2 3 a a (0.2s ~ 0.4s) are within the same cluster;
// 0 1 a a (0.1s ~ 0.5s) and 5 6 b b (0.2s ~ 0.4s) are in different clusters;
// 0 1 a a (0.1s ~ 0.5s) and 7 8 a a (0.9s ~ 1.4s) are also in different clusters.
// It puts disambiguating symbols in the olabels, leaving the words on the
// ilabels.
bool ClusterLattice(CompactLattice *clat,
                    const std::vector<int32> &state_times);

// This function contains two steps: weight pushing and factor generation. The
// original ShortestDistance() is not very efficient, so we do the weight
// pushing and shortest path manually by computing the alphas and betas. The
// factor generation step expand the lattice to the LXTXT' semiring, with
// additional start state and end state (and corresponding arcs) added.
bool CreateFactorTransducer(const CompactLattice &clat,
                            const std::vector<int32> &state_times,
                            int32 utterance_id,
                            KwsProductFst *factor_transducer);

// This function removes the arcs with long silence. By "long" we mean arcs with
// #frames exceeding the given max_silence_frames. We do this filtering because
// the gap between adjacent words in a keyword must be <= 0.5 second.
// Note that we should not remove the arcs created in the factor generation
// step, so the "search area" is limited to the original arcs before factor
// generation.
void RemoveLongSilences(int32 max_silence_frames,
                        const std::vector<int32> &state_times,
                        KwsProductFst *factor_transducer);

// Do the factor merging part: encode input and output, and apply weighted
// epsilon removal, determinization and minimization.  Modifies factor_transducer.
void DoFactorMerging(KwsProductFst *factor_transducer,
                     KwsLexicographicFst *index_transducer);

// Do the factor disambiguation step: remove the cluster id's for the non-final
// arcs and insert disambiguation symbols for the final arcs
void DoFactorDisambiguation(KwsLexicographicFst *index_transducer);

// Do the optimization: do encoded determinization, minimization
void OptimizeFactorTransducer(KwsLexicographicFst *index_transducer,
                              int32 max_states,
                              bool allow_partial);

// the following two functions will, if GetVerboseLevel() >= 2, check that the
// cost of the second-best path in the transducers is not negative, and print
// out some associated debugging info if GetVerboseLevel() >= 3.  The best path
// in the transducers will typically be for the empty word sequence, and it may
// have negative cost (i.e. probability more than one), but the second-best one
// should not have negative cost.  A warning will be printed if
// GetVerboseLevel() >= 2 and a substantially negative cost is found.
void MaybeDoSanityCheck(const KwsProductFst &factor_transducer);
void MaybeDoSanityCheck(const KwsLexicographicFst &index_transducer);


// this Mapper class is used in some of the the internals; we have to declare it
// in the header because, for the sake of compilation time, we split up the
// implementation into two .cc files.
class KwsProductFstToKwsLexicographicFstMapper {
 public:
  typedef KwsProductArc FromArc;
  typedef KwsProductWeight FromWeight;
  typedef KwsLexicographicArc ToArc;
  typedef KwsLexicographicWeight ToWeight;

  KwsProductFstToKwsLexicographicFstMapper() {}

  inline ToArc operator()(const FromArc &arc) const {
    return ToArc(arc.ilabel,
                 arc.olabel,
                 (arc.weight == FromWeight::Zero() ?
                  ToWeight::Zero() :
                  ToWeight(arc.weight.Value1().Value(),
                           StdLStdWeight(arc.weight.Value2().Value1().Value(),
                                         arc.weight.Value2().Value2().Value()))),
                 arc.nextstate);
  }

  fst::MapFinalAction FinalAction() const { return fst::MAP_NO_SUPERFINAL; }

  fst::MapSymbolsAction InputSymbolsAction() const { return fst::MAP_COPY_SYMBOLS; }

  fst::MapSymbolsAction OutputSymbolsAction() const { return fst::MAP_COPY_SYMBOLS; }

  uint64 Properties(uint64 props) const { return props; }
};

// This is the normal version of LatticeToKwsIndex which does not modify input
// lattice. Creates an inverted KWS index of the given lattice. The output KWS
// index is over the KwsLexicographicWeight semiring (a triplet of tropical
// weights with lexicographic ordering). Input lattice should be topologically
// sorted. max_silence_frames (if non-negative) determines the duration of the
// longest silence (epsilon) arcs allowed in the output. silence arcs longer
// than max_silence_frames will be removed. max_states (if positive) determines
// the maximum number of states allowed in the output. allow_partial determines
// whether to allow partial output or skip determinization if determinization
// fails. For details of the algorithm, see: Dogan Can and Murat Saraclar, 2011,
// "Lattice Indexing for Spoken Term Detection".
bool LatticeToKwsIndex(const CompactLattice &clat,
                       int32 utterance_id,
                       int32 max_silence_frames,
                       int32 max_states,
                       bool allow_partial,
                       KwsLexicographicFst *index_transducer);

// This is the destructive version of LatticeToKwsIndex which modifies input
// lattice.
bool LatticeToKwsIndexDestructive(CompactLattice *clat,
                                  int32 utterance_id,
                                  int32 max_silence_frames,
                                  int32 max_states,
                                  bool allow_partial,
                                  KwsLexicographicFst *index_transducer);

// Optimizes KWS index by doing encoded epsilon removal, determinization and
// minimization. max_states (if positive) determines the maximum number of
// states allowed in the output.
void OptimizeKwsIndex(KwsLexicographicFst *index, int32 max_states = -1);

// Encode labels on final arcs. Replace output labels of final arcs (utterance
// ids) with the encoded labels. Replace input labels of final arcs
// (disambiguation symbols) with epsilons.
void EncodeKwsDisambiguationSymbols(
    KwsLexicographicFst *index,
    fst::internal::EncodeTable<KwsLexicographicArc> *encode_table);

// this is a mapper adapter that helps converting
// between the StdArc FST (i.e. tropical semiring FST)
// to the KwsLexicographic FST. Structure will be kept,
// the weights converted/recomputed
class VectorFstToKwsLexicographicFstMapper {
 public:
  typedef fst::StdArc FromArc;
  typedef FromArc::Weight FromWeight;
  typedef KwsLexicographicArc ToArc;
  typedef KwsLexicographicWeight ToWeight;

  VectorFstToKwsLexicographicFstMapper() {}

  ToArc operator()(const FromArc &arc) const {
    return ToArc(arc.ilabel,
                 arc.olabel,
                 (arc.weight == FromWeight::Zero() ?
                  ToWeight::Zero() :
                  ToWeight(arc.weight.Value(),
                           StdLStdWeight::One())),
                 arc.nextstate);
  }

  fst::MapFinalAction FinalAction() const {
    return fst::MAP_NO_SUPERFINAL;
  }

  fst::MapSymbolsAction InputSymbolsAction() const {
    return fst::MAP_COPY_SYMBOLS;
  }

  fst::MapSymbolsAction OutputSymbolsAction() const {
    return fst::MAP_COPY_SYMBOLS;
  }

  uint64 Properties(uint64 props) const { return props; }
};

// Searches given keyword (FST) inside the KWS index (FST). Returns the n_best
// results found. Each result is a tuple of (utt_id, time_beg, time_end, score).
// The encode_table is used for decoding output labels into utterance ids. If
// matched_seq is non-null, it is set to the result of composition with the
// index.
bool SearchKwsIndex(
    const KwsLexicographicFst &index,
    const fst::StdVectorFst &keyword,
    const fst::internal::EncodeTable<KwsLexicographicArc> &encode_table,
    int32 n_best,
    std::vector<std::tuple<int32, int32, int32, double>> *results,
    KwsLexicographicFst *matched_seq = NULL);

// Computes detailed statistics about the individual index matches.
// Since keyword is an FST, there can be multiple matching paths in the keyword
// and the index in a given time period. The stats output will provide the
// results for all matching paths each with the appropriate score. The ilabels
// output will provide the input labels on those paths.
void ComputeDetailedStatistics(
    const KwsLexicographicFst &keyword,
    const fst::internal::EncodeTable<KwsLexicographicArc> &encode_table,
    std::vector<std::tuple<int32, int32, int32, double> > *stats,
    std::vector<std::vector<KwsLexicographicArc::Label> > *ilabels);

} // namespace kaldi


#endif  // KALDI_KWS_KWS_FUNCTIONS_H_
