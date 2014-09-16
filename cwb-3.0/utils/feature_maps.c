/* 
 *  IMS Open Corpus Workbench (CWB)
 *  Copyright (C) 1993-2006 by IMS, University of Stuttgart
 *  Copyright (C) 2007-     by the respective contributers (see file AUTHORS)
 * 
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2, or (at your option) any later
 *  version.
 * 
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 *  Public License for more details (in the file "COPYING", or available via
 *  WWW at http://www.gnu.org/copyleft/gpl.html).
 */


#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <string.h>

/* #include <sys/types.h> */
/* #include <sys/stat.h> */

#include "feature_maps.h"
#include "barlib.h"

/** the top of the range of char_map's outputs @see char_map */
int char_map_range=0;
/** a character map for accented characters. */
unsigned char char_map[256];

/** initialises char_mpa, qv @see char_map */
void
init_char_map()
{
  int i;
  unsigned char *map=char_map;
  unsigned char 
    map_from[]="¿¡¬√ƒ≈∆«»… ÀÃÕŒœ–—“”‘’÷ÿŸ⁄€‹›ﬁﬂ‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ¯˘˙˚¸˝˛ˇ",
    map_to[]  ="AAAAAAACEEEEIIIIDNOOOOOOUUUUYFSAAAAAAACEEEEIIIIDNOOOOOOUUUUYFY",
    *f=map_from,
    *t=map_to;

  for(i=0;i<256;i++) map[i]=0;

  while(*f) {
    map[*f++]=*t++;
  }

  for(i='A';i<='Z';i++) map[i]=i;
  for(i='a';i<='z';i++) map[i]=i-'a'+'A'; 
  
  for(i=1;i<256;i++) {
    if(map[i]>0) map[i]-='A'-2; 
    else map[i]=1;
    
    if(map[i]>=char_map_range) {
      char_map_range=map[i]+1;
    }
  }
}




/*

  FMS = create_feature_maps(config, config_lines, source, target, source_s, target_s);

  Gegeben: Feature-Map-Konfiguration (ASCII, in einzelne Eintraege aufgeteilt)
           Word- oder Lemma-Attribut von Quellcorpus(source) und Zielcorpus(target),
           Satzmarkierungen fuer beide Corpora (source_s, target_s)

  Gesucht: Menge der relevanten Features, Abbildung der jeweiligen
           Wˆrter in Mengen von Features (Featuremaps).
           Wird zusammen mit den Attributen in FMS-Struktur zurueckgeliefert.

  Um eine kompakte Kodierung zu erhalten, wird der Aufbau der
  Feature-Vektoren in zwei Schritten durchgef¸hrt:
  1. Features identifizieren und Anzahl pro Wort ermitteln
  2. Aufbau der Tabellen

*/

/**
 * Creates feature maps for a source/target corpus pair.
 *
 * Example usage:
 *
 * FMS = create_feature_maps(config_data, nr_of_config_lines, source_word, target_word, source_s, target_s);
 *
 * @param config              pointer to a list of strings representing the feature map configuration.
 * @param config_lines        the number of configuration items stored in config_data.
 * @param w_attr1             The p-attribute in the first corpus to link.
 * @param w_attr2             The p-attribute in the second corpus to link.
 * @param s_attr1             The s-attribute in the first corpus to link.
 * @param s_attr2             The s-attribute in the second corpus to link.
 * @return                    the new FMS object.
 */
FMS
create_feature_maps(char **config,
                    int config_lines,
                    Attribute *w_attr1,
                    Attribute *w_attr2,
                    Attribute *s_attr1,
                    Attribute *s_attr2
                    ) 
{
  FMS r;
  unsigned int *fcount1, *fcount2;
  int config_pointer;
  char *b, command[200], dummy[200];
  int current_feature,
      weight,
    need_to_abort;
  int *fs1, *fs2; 
  int i,nw1,nw2;


  r = (FMS) malloc(sizeof(feature_maps_t));
  assert(r);

  r->att1 = w_attr1;
  r->att2 = w_attr2;
  r->s1 = s_attr1;
  r->s2 = s_attr2;

  init_char_map();
  
  nw1= cl_max_id(w_attr1);
  if (nw1 <= 0) {
    fprintf(stderr, "ERROR: can't access lexicon of source corpus\n");
    exit(1);
  }
  nw2= cl_max_id(w_attr2);
  if (nw2 <= 0) {
    fprintf(stderr, "ERROR: can't access lexicon of target corpus\n");
    exit(1);
  }
  
  printf("LEXICON SIZE: %d / %d\n", nw1, nw2);

  fcount1 = (unsigned int*) calloc(nw1+1,sizeof(unsigned int));
  fcount2 = (unsigned int*) calloc(nw2+1,sizeof(unsigned int));

  r->n_features=1;

  /* process feature map configuration: first pass */
  for (config_pointer = 0; config_pointer < config_lines; config_pointer++) {

    if ( (b = strpbrk(config[config_pointer],"\n#")) )  /* strip newline and comments */
      *b=0;
    if (sscanf(config[config_pointer],"%s",command)>0) {
      if(command[0]=='-') {
        switch(command[1]) {
        case 'S': {
          int i1, i2, f1, f2;
          float threshold;
          int n_shared=0;
            
          if(sscanf(config[config_pointer],"%2s:%d:%f %s",command,&weight,&threshold,dummy)!=3) {
            fprintf(stderr,"ERROR: wrong # of args: %s\n",config[config_pointer]);
            fprintf(stderr,"Usage: -S:<weight>:<threshold>\n");
            fprintf(stderr,"  Shared words with freq. ratios f1/(f1+f2) and f2/(f1+f2) >= <threshold>.\n");
            exit(1);
          }
          else {
            printf("FEATURE: Shared words, threshold=%4.1f%c, weight=%d ... ",threshold * 100, '\%', weight);
            fflush(stdout);
            for (i1=0; i1 < nw1; i1++) {
              f1 = cl_id2freq(w_attr1, i1);
              i2 = cl_str2id(w_attr2, cl_id2str(w_attr1, i1));
              if (i2 >= 0){
                f2 = cl_id2freq(w_attr2, i2);
                if (f1 / (0.0+f1+f2) >=threshold && f2 / (0.0+f1+f2) >= threshold){
                  fcount1[i1]++;
                  fcount2[i2]++;
                  n_shared++;
                  r->n_features++; 
                }
              }
            }
            printf("[%d]\n",n_shared);
          }
          break;
        }
        case '1': 
        case '2':
        case '3':
        case '4': { 
          int n;
          
          if (sscanf(config[config_pointer],"%1s%d:%d %s",command,&n,&weight,dummy)!=3) {
            fprintf(stderr,"ERROR: wrong # of args: %s\n",config[config_pointer]);
            fprintf(stderr,"Usage: -<n>:<weight>  (n = 1..4)\n");
            fprintf(stderr,"  Shared <n>-grams (single characters, bigrams, trigrams, 4-grams).\n");
            exit(1);
          }
          else if(n <= 0 || n>4) {
            /* this shouldn't happen anyway */
            fprintf(stderr,"ERROR: cannot handle %d-grams: %s\n",n,config[config_pointer]);
            exit(1);
          }
          else {
            int i,f,l;

            printf("FEATURE: %d-grams, weight=%d ... ", n, weight);
            fflush(stdout);

            for(i=0; i<nw1; i++) {
              l = cl_id2strlen(w_attr1, i);
              fcount1[i] += (l >= n) ? l - n + 1 : 0;
            }
            for(i=0; i<nw2; i++) {
              l = cl_id2strlen(w_attr2, i);
              fcount2[i] += (l >= n) ? l - n + 1 : 0;
            }
            f=1;
            for(i=0;i<n;i++)
              f*=char_map_range;
            r->n_features+=f;           
            printf("[%d]\n", f);
          }
          break;
        }
        case 'W': {
          char filename[200],
            word1[200],
            word2[200];
          FILE *wordlist;
          int nw,nl=0,i1,i2,n_matched=0;

          if(sscanf(config[config_pointer],"%2s:%d:%s %s",command,&weight,filename,dummy)!=3) {
            fprintf(stderr, "ERROR: wrong # of args: %s\n",config[config_pointer]);
            fprintf(stderr, "Usage: -W:<weight>:<filename>\n");
            fprintf(stderr, "  Word list (read from file <filename>).\n");
            exit(1);
          }
          else if(!(wordlist=fopen(filename,"r"))) {
            fprintf(stderr,"ERROR: Cannot read word list file %s.\n",
                    filename);
            exit(-1);
          }
          else {
            printf("FEATURE: word list %s, weight=%d ... ", filename, weight);
            fflush(stdout);
            while((nw=fscanf(wordlist,"%s %s",word1,word2))>0) {
              nl++;
              if (nw!=2) fprintf(stderr,"WARNING: Line %d in word list '%s' contains %d words, ignored.\n",
                                 nl,filename,nw);
              else {
                if((i1=cl_str2id(w_attr1,word1))>=0
                   && (i2=cl_str2id(w_attr2,word2)) >=0) {
                  fcount1[i1]++;
                  fcount2[i2]++;
                  n_matched++;
                  r->n_features++;
                }
              }
            }
            fclose(wordlist);
            printf("[%d]\n", n_matched);
          }         
          break;
        }
        case 'C': 
          if(sscanf(config[config_pointer],"%2s:%d %s",command,&weight,dummy)!=2) {
            fprintf(stderr, "ERROR: wrong # of args: %s\n",config[config_pointer]);
            fprintf(stderr, "Usage: -C:<weight>\n");
            fprintf(stderr, "  Character count [primary feature].\n");
            exit(1);
          }
          else {
            /* primary feature -> don't create additional features */
            /* first entry in a token's feature list is character count */ 
            for (i=0; i<nw1; i++) fcount1[i]++;
            for (i=0; i<nw2; i++) fcount2[i]++;
            printf("FEATURE: character count, weight=%d ... [1]\n", weight);
          }
          break;
        default: fprintf(stderr,"ERROR: unknown feature: %s\n",config[config_pointer]);
          exit(1);
          break;
        }
      }
      else {
        fprintf(stderr,"ERROR: feature parse error: %s\n", config[config_pointer]);
        exit(1);
      }
    }
  }

  printf("[%d features allocated]\n",r->n_features);

  for(i=1; i<=nw1;i++) fcount1[i]+=fcount1[i-1];
  for(i=1; i<=nw2;i++) fcount2[i]+=fcount2[i-1];
  printf("[%d entries in source text feature map]\n", fcount1[nw1]);
  printf("[%d entries in target text feature map]\n", fcount2[nw2]);


  fs1=(int*)malloc(sizeof(int)*fcount1[nw1]); assert(fs1);
  fs2=(int*)malloc(sizeof(int)*fcount2[nw2]); assert(fs2);
  
  r->w2f1=(int **)malloc(sizeof(unsigned int *)*(nw1+1)); assert(r->w2f1);
  r->w2f2=(int **)malloc(sizeof(unsigned int *)*(nw2+1)); assert(r->w2f2);

  for(i=0;i<=nw1;i++) r->w2f1[i]=fs1+fcount1[i];
  for(i=0;i<=nw2;i++) r->w2f2[i]=fs2+fcount2[i];

  r->fweight=(int*)calloc(r->n_features,sizeof(int)); assert(r->fweight);
  r->vstack=NULL;


  /* process feature map configuration: second pass */
  current_feature=1; 
  for (config_pointer = 0; config_pointer < config_lines; config_pointer++) {

    if ( (b = strpbrk(config[config_pointer],"\n#")) )
      *b=0;
    if(sscanf(config[config_pointer],"%s",command)>0) {
      if(command[0]=='-') {
        switch(command[1]) {
        case 'S': {
          int i1, i2, f1, f2;
          float threshold;
          
          if(sscanf(config[config_pointer],"%2s:%d:%f %s",command,&weight,&threshold,dummy)!=3);
          else {
            printf("PASS 2: Processing shared words (th=%4.1f%c).\n", threshold * 100, '\%');
            for(i1=0; i1<nw1;i1++) {
              f1=cl_id2freq(w_attr1,i1);
              i2=cl_str2id(w_attr2, cl_id2str(w_attr1, i1));
              if(i2>=0){
                f2=cl_id2freq(w_attr2,i2);
                if(f1/(0.0+f1+f2)>=threshold && f2/(0.0+f1+f2)>=threshold){
                  *(--r->w2f1[i1])=*(--r->w2f2[i2])=current_feature; 
                  r->fweight[current_feature]=weight;
                  current_feature++;
                }
              }
            }
          }
          break;
        }
        case '1':
        case '2':
        case '3':
        case '4': { 
          int n;

          if(sscanf(config[config_pointer],"%1s%d:%d %s",command,&n,&weight,dummy)!=3);
          else if(n<=0 || n>4) ;
          else {
            int i,f,ng,l;
            unsigned char *s;

            printf("PASS 2: Processing %d-grams.\n",n);

            f=1;
            for(i=0;i<n;i++)
              f*=char_map_range;

            for(i=current_feature;i<current_feature+f;i++)
              r->fweight[i]=weight;

            for(i=0; i<nw1; i++) {
              s = (unsigned char *) cl_id2str(w_attr1,i);
              ng=0; l=0;
              while (*s) {
                /* read and process 1 character */
                ng=(ng*char_map_range+char_map[*s]) % f;
                l++; s++;
                /* begin setting features as soon as we've accumulated the first N-gram */
                if (l >= n) *(--r->w2f1[i]) = current_feature + ng;
              }
            }

            for(i=0; i<nw2; i++) {
              s = (unsigned char *) cl_id2str(w_attr2,i);
              ng=0; l=0;
              while (*s) {
                /* read and process 1 character */
                ng=(ng*char_map_range+char_map[*s]) % f;
                l++; s++;
                /* begin setting features as soon as we've accumulated the first N-gram */
                if (l >= n) *(--r->w2f2[i]) = current_feature + ng;
              }
            }
            
            current_feature+=f;
          }
          break;
        }
        case 'W': {
          char filename[200],
            word1[200],
            word2[200];
          FILE *wordlist;
          int nw,nl=0,i1,i2;

          if(sscanf(config[config_pointer],"%2s:%d:%s %s",command,&weight,filename,dummy)!=3);
          else if(!(wordlist=fopen(filename,"r"))) exit(-1);
          else {
            printf("PASS 2: Processing word list %s\n",filename);
            while((nw=fscanf(wordlist,"%s %s",word1,word2))>0) {
              nl++;
              if (nw!=2) { /* skip */ }
              else {
                if((i1=cl_str2id(w_attr1,word1))>=0
                   && (i2=cl_str2id(w_attr2,word2)) >=0) {
                  *(--r->w2f1[i1])=*(--r->w2f2[i2])=current_feature; 
                  r->fweight[current_feature]=weight;
                  current_feature++;
                }
              }
            }
            fclose(wordlist);
          }         
          break;
        }
        case 'C': 
          if (sscanf(config[config_pointer],"%2s:%d %s",command,&weight,dummy) == 2) {
            printf("PASS 2: Setting character count weight.\n");
            if (r->fweight[0] != 0) {
              fprintf(stderr, "WARNING: Character count weight redefined (new value is %d)\n", weight);
            }
            /* primary feature */
            r->fweight[0] = weight;
          }
          break;
        default: ;
        }
      }
    }
  }

  printf("PASS 2: Creating character counts.\n");
  for(i=0; i<nw1; i++) {
    *(--r->w2f1[i]) = cl_id2strlen(w_attr1, i);
  }
  for(i=0; i<nw2; i++) {
    *(--r->w2f2[i]) = cl_id2strlen(w_attr2, i);
  }

  printf("[checking pointers]\n");

  need_to_abort=0;
  for(i=1;i<nw1;i++) {
    if(r->w2f1[i+1]-r->w2f1[i]!=fcount1[i]-fcount1[i-1]) {
      fprintf(stderr,"ERROR: fcount1[%d]=%d r->w2f1[%d]-r->w2f1[%d]=%ld w=``%s''\n",
              i,fcount1[i]-fcount1[i-1], i+1, i,(long int)(r->w2f1[i+1]-r->w2f1[i]),
              cl_id2str(w_attr1,i));
      need_to_abort=1;
    }
  }

  for(i=1;i<nw2;i++) {
    if(r->w2f2[i+1]-r->w2f2[i]!=fcount2[i]-fcount2[i-1]) {
      fprintf(stderr,"ERROR: fcount2[%d]=%d r->w2f2[%d]-r->w2f2[%d]=%ld w=``%s''\n",
              i,fcount2[i]-fcount2[i-1], i+1, i,(long int)(r->w2f2[i+1]-r->w2f2[i]),
              cl_id2str(w_attr2,i));
      need_to_abort=1;
    }
  }

  if(need_to_abort) exit(-1);

  free(fcount1);
  free(fcount2);

  return(r);
}


/**
 *
 * Sim = feature_match(FMS, source_first, source_last, target_first, target_last);
 *
 * Compute similarity measure for source and target regions, where *_first and *_last
 * specify the index of the first and last sentence in a region.
 *
 * @param fms  The feature map
 * @param f1   Index of first sentence in source region.
 * @param l1   Index of last sentence in source region
 * @param f2   Index of first sentence in target region.
 * @param l2   Index of last sentence in target region.
 * @return     The similarity measure.
 */
int
feature_match(feature_maps_t* fms, 
              int f1,
              int l1,
              int f2,
              int l2)
{

  int *fcount;
  int match, j, i, id, *f;
  int cc1=0, cc2=0;             /* character count */
  int from, to;                 /* sentence boundaries */
  
 
  fcount=get_fvector(fms);

  for (j = f1; j <= l1; j++) {  /* count features in source region */
    if (get_bounds_of_nth_struc(fms->s1, j, &from, &to)) 
      for (i = from; i <= to; i++) {    /* process sentence */
        id = get_id_at_position(fms->att1, i);
        if (id >= 0) {
          f = fms->w2f1[id];
          cc1 += *(f++);                /* character count */
          for( ; f < fms->w2f1[id+1]; f++)
            fcount[*f]++;
        }
      }
  }

  match=0;                      /* sum up similarity measure */

  for (j = f2; j <= l2; j++) {  /* compare to features in target region */
    if (get_bounds_of_nth_struc(fms->s2, j, &from, &to))
      for(i=from; i<= to; i++) {        /* process sentence */
        id=get_id_at_position(fms->att2, i);
        if (id >= 0) {
          f = fms->w2f2[id];
          cc2 += *(f++);                /* character count */
          for( ; f < fms->w2f2[id+1]; f++) {
            if(fcount[*f]>0) {
              fcount[*f]--;
              match += fms->fweight[*f];
            }
          }
        }
      }
  }
  
  /* add character count value to match quality */
  match += fms->fweight[0] * ((cc1 <= cc2) ? cc1 : cc2);

  /* clear feature count vector (selectively) */
  
  for (j = f1; j <= l1; j++) {  
    if (get_bounds_of_nth_struc(fms->s1, j, &from, &to)) 
      for(i=from; i<= to; i++) {
        id=get_id_at_position(fms->att1,i);
        if (id >= 0) {
          for(f = fms->w2f1[id]+1; f < fms->w2f1[id+1]; f++)
            fcount[*f]=0;
        }
      }
  }
  release_fvector(fcount, fms);

  return match;
}


/**
 * Feature count vector handling (used internally by feature_match).
 */
int *
get_fvector(FMS fms){
  int * res;
  vstack_t *next;

  if(!fms->vstack) {
    return((int*)calloc(fms->n_features,sizeof(int)));
  }
  else {
    res=fms->vstack->fcount;
    next=fms->vstack->next;
    free(fms->vstack);
    fms->vstack=next;
    return(res);
  }

};

/**
 * Inserts a new vstack_t at the start of the vstack member of the given FMS.
 *
 * {That's what it looks like it does, not sure how the function name fits with that... ???? - AH}
 */
void
release_fvector(int *fvector, FMS fms)
{
  vstack_t *new;
  
  new=(vstack_t*)malloc(sizeof(vstack_t)); assert(new);
  new->fcount=fvector;
  new->next=fms->vstack;
  fms->vstack=new;
}


/**
 * Prints a message about the vector stack of the given FMS.
 *
 * If it finds a non-zero-count, it prints a message to STDERR.
 * If it doesn't, it prints a message to STDOUT with the count of feature vectors.
 *
 * @param fms  The FMS to check.
 */
void
check_fvectors(FMS fms)
{

  int i, n;
  vstack_t * agenda;

  n=0;
  agenda=fms->vstack;

  while(agenda) {
    n++;
    for(i=0; i<fms->n_features; i++)
      if(agenda->fcount[i]!=0) {
        fprintf(stderr,"WARNING: non-zero count detected\n");
        return;
      }

    agenda=agenda->next;
  }
  
  printf("[check_fvectors: All %d feature vectors empty]\n",n);
}


/**
 * Prints the features in an FMS to STDOUT.
 *
 * Usage: show_feature(FMS, 1/2, "word");
 *
 * This will print all features listed in FMS for the token "word"; "word" is looked up in the
 * source corpus if the 2nd argument == 1, and in the target corpus otherwise.
 *
 * @param fms    The FMS to print from.
 * @param which  Which corpus to look up? (See function description)
 * @param word   The token to look up.
 */
void
show_features(FMS fms, int which, char* word)
{
  int id, *f;
  Attribute *att;
  int **w2f;

  att = (which==1) ? (fms->att1) : (fms->att2);
  w2f = (which==1) ? (fms->w2f1) : (fms->w2f2);
  
  id=get_id_of_string(att, word);

  printf("FEATURES of '%s', id=%d :\n", word, id);
  printf("+ len=%2d  weight=%3d\n", *w2f[id], fms->fweight[0]);
  for(f=w2f[id]+1; f<w2f[id+1];f++)
    printf("+ %6d  weight=%3d\n",*f,fms->fweight[*f]);
  
}



/**
 * Finds the best alignment path for the given regions of sentences in source and
 * target corpus.
 *
 * This function does a beamed dynamic programming search for the best path
 * aligning the sentence regions (f1,l1) in the source corpus and (f2,l2)
 * in the target corpus.
 *
 * Allowed alignments are 1:0 0:1 1:1 2:1 1:2.
 *
 * The results are returned in the vectors out1 and out2,
 * which each contain a number of valid entries (alignment points) equal to {steps}.
 *
 * Alignment points are given as sentence numbers and
 * correspond to the start points of the sentences. At the end-of-region alignment
 * point, sentence numbers will be l1 + 1 and l2 + 1, which must be considered by
 * the caller if l1 (or l2) is the last sentence in the corpus!
 *
 * The similarity measures of aligned regions are returned in the vector out_quality.
 *
 * Memory allocated for the return vectors (out1, out2, out_quality) is managed by best_path() and
 * must not be freed by the caller. Calling best_path()  overwrites
 * the results of the previous search.
 *
 * Example usage:
 *
 * best_path(FMS, f1, l1, f2, l2, beam_width, 0/1,
 *           &steps, &out1, &out2, &out_quality);
 *
 * @param fms          The FMS to use.
 * @param f1           Index of first sentence in source region.
 * @param l1           Index of last sentence in source region
 * @param f2           Index of first sentence in target region.
 * @param l2           Index of last sentence in target region.
 * @param beam_width   Parameter for the beam search.
 * @param verbose      Boolean: iff true, prints progress messages on STDOUT.
 * @param steps        Put output here (see function description).
 * @param out1         Put output here (see function description).
 * @param out2         Put output here (see function description).
 * @param out_quality  Put output here (see function description).
 */
void
best_path(FMS fms,
          int f1,
          int l1,
          int f2,
          int l2,
          int beam_width,       /* beam search */
          int verbose,          /* print progress info on stdout ? */
          /* output */
          int *steps,
          int **out1,
          int **out2,
          int **out_quality)
{

  BARdesc quality, next_x, next_y;
  
  static int max_out_pos=0;
  static int *x_out = NULL;
  static int *y_out = NULL;
  static int *q_out = NULL;

  int ix, iy, iq, id, idmax, index, dx, dy, aux;
  int x_start, x_end, x_max, q_max;     /* beam search stuff */
  int half_beam_width = beam_width / 2;
  int x_ranges = l1 - f1 + 1, y_ranges = l2 - f2 + 1;

  /* allocate/enlarge output arrays if necessary */
  /* if all alignements are 1:0 or 0:1 -> x_ranges+y_ranges + 1 pts */
  if (x_ranges + y_ranges + 1 > max_out_pos) {
    x_out = (int*)realloc(x_out, sizeof(int) * (x_ranges+y_ranges+1));
    y_out = (int*)realloc(y_out, sizeof(int) * (x_ranges+y_ranges+1));
    q_out = (int*)realloc(q_out, sizeof(int) * (x_ranges+y_ranges+1));
    max_out_pos = x_ranges+y_ranges+1; 
  }
  /* allocate data array for dynamic programming */
  quality = BAR_new(x_ranges+1, y_ranges+1, beam_width);
  next_x = BAR_new(x_ranges+1, y_ranges+1, beam_width);
  next_y = BAR_new(x_ranges+1, y_ranges+1, beam_width);

  /* init values at (0,0) position */
  BAR_write(quality, 0,0, 1); /* this ensures we can't get lost, since any path connected to
                                   the origin has at least a quality of 1 */
  BAR_write(next_x, 0,0, 0);
  BAR_write(next_y, 0,0, 0);
  x_max = 1;                    /* beam center init value */

  /* forward diagonal dynamic programming loop with beam search */
  idmax = x_ranges + y_ranges;
  for (id = 1; id <= idmax; id++) {

    x_start = x_max - half_beam_width;
    x_end = x_start + beam_width;
    x_max = x_start; q_max = 0; /* scan for best path on diagonal => new x_max value */

    for(ix = x_start; ix < x_end; ix++) {
      iy = id - ix;
      if ((iy < 0) || (iy > y_ranges) || (ix > x_ranges))
        continue;
      
      /* initialise to 1:0 or 0:1 alignment (whichever is better) */
      if (ix >= 1) {            /* 1:0 if possible */
        BAR_write(quality, ix,iy, BAR_read(quality, ix-1,iy)); 
        BAR_write(next_x, ix,iy, ix - 1);
        BAR_write(next_y, ix,iy, iy);
      }
      if(BAR_read(quality, ix,iy-1) > BAR_read(quality, ix,iy)) {
        /* 0:1 alignment, if that is an improvement */
        BAR_write(quality, ix,iy, BAR_read(quality, ix,iy-1));
        BAR_write(next_x, ix,iy, ix);
        BAR_write(next_y, ix,iy, iy-1);
      } 

      /* scan through all possible alignment steps */
      for(dx=1; dx <= 2; dx++) {
        for(dy=1; dy <= 2; dy++) {
          /*      if ((dx == 2) && (dy == 2)) continue; */ /* 2:2 now allowed again */
          if ((ix - dx >= 0) && (iy - dy >= 0)) {
            aux = BAR_read(quality, ix-dx,iy-dy)
              + feature_match(fms, 
                              f1 + ix - dx, f1 + ix - 1,
                              f2 + iy - dy, f2 + iy - 1);
            if (aux > BAR_read(quality, ix,iy)) {
              BAR_write(quality, ix,iy, aux);
              BAR_write(next_x, ix, iy, ix-dx);
              BAR_write(next_y, ix, iy, iy-dy);
            }
          }
        }
      }
      
      /* find best path on current diagonal */
      if (BAR_read(quality, ix,iy) > q_max) {
        x_max = ix;
        q_max = BAR_read(quality, ix, iy);
      }
    } /* end of x coordinate loop (diagonal parametrisation) */
    /* new x_max is predicted to be the same as x_max determined for current diagonal */
    if (verbose) { 
      printf("BEST_PATH: scanning diagonal #%d of %d [max sim = %d]        \r",
             id, idmax, q_max);
      fflush(stdout);
    }
  } /* end of diagonal loop */
  /* end of DP loop */
  if (verbose) printf("\n");
  
  /* read best path from DP array (backward) */
  ix = x_ranges; 
  iy = y_ranges;
  iq = BAR_read(quality, ix, iy);
  
  *steps = 0;
  index = max_out_pos - 1; 
  while ((ix >= 0) && (iy >= 0)) { /* the while() condition is just a safety check */
    x_out[index] = ix + f1;
    y_out[index] = iy + f2;
    aux = BAR_read(quality, ix, iy);
    q_out[index] = iq - aux;
    iq = aux;
    (*steps)++;
    if ((ix <= 0) && (iy <= 0)) break; /* exit point */
    aux = ix;                   /* next step */
    ix = BAR_read(next_x, aux, iy);
    iy = BAR_read(next_y, aux, iy);
    index--;
  }
  
  *out1 = x_out + index;
  *out2 = y_out + index;
  *out_quality = q_out + index;

  /* deallocate dynamic programming data */
  BAR_delete(quality);
  BAR_delete(next_x);
  BAR_delete(next_y);
}

